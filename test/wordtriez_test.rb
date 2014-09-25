# coding: utf-8
require "test/unit"
require_relative "../lib/wordtriez"

GC.stress

class WordtriezTest < Test::Unit::TestCase
  def test_init_type_options
    t = Wordtriez.new value_type: :int64
    assert_equal :int64, t.value_type
    t = Wordtriez.new value_type: :object
    assert_equal :object, t.value_type
    t = Wordtriez.new
    assert_equal :int64, t.value_type

    assert_raise ArgumentError do
      Wordtriez.new value_type: :string
    end
    assert_raise ArgumentError do
      Wordtriez.new invalid_option: :int64
    end
  end

  def test_hat_trie
    t = Wordtriez.new value_type: :object

    v1 = (1 << 40)
    v2 = (1 << 141)
    t['万塘路一锅鸡'] = v1
    t['万塘路'] = v2
    assert_equal v1, t['万塘路一锅鸡']
    assert_equal v2, t['万塘路']
    assert_equal nil, t['万']
    assert_equal false, t.has_key?('万')
    assert_equal true, t.has_key?('万塘路')

    assert_equal v1, t.delete('万塘路一锅鸡')
    assert_equal nil, t['万塘路一锅鸡']
    assert_equal v2, t['万塘路']

    a = t.search ''
    assert_equal [['万塘路', v2]], a

    t['马当路'] = 3
    a = t.search '万塘'
    assert_equal [['路', v2]], a
  end

  def test_insertion_and_search_on_many_keys
    t = Wordtriez.new
    as = ('A'..'z').to_a
    bs = ('一'..'百').to_a
    as.each do |a|
      # 10k chars to ensure burst
      bs.each do |b|
        t[a + b] = 0
      end
    end
    assert_equal as.size * bs.size, t.size

    a = t.search 'a'
    assert_equal bs.to_a, a.map(&:first).sort

    a = []
    t.search 'b', sort: true, limit: 3 do |k, v|
      a << k
    end
    assert_equal 3, a.size
    assert_equal a, a.sort
  end

  def test_each_and_raise
    t = Wordtriez.new
    t['abcd'] = 0
    t['abc'] = 1

    assert_raise NameError do
      t.each do |k, v|
        raise NameError, k
      end
    end

    assert_raise ArgumentError do
      t.each
    end
  end

  def test_append
    t = Wordtriez.new
    ('a'..'z').each do |c|
      t << c
    end
    assert_equal 26, t.size
    assert_equal 0, t['c']
    assert_equal true, t.has_key?('c')
  end

  def test_full_text_search
    sequences = {
      'ACTGAAAAAAACTG' => 1,
      'ATACGGTCCA' => 2,
      'GCTTGTACGT' => 3
    }
    t = Wordtriez.new
    sequences.each do |seq, id|
      t.change_all(:suffix, seq){ id }
    end
    assert_equal 2, t.search('CGGT').map(&:last).flatten.first
  end

  def test_nul_char_in_keys
    t = Wordtriez.new
    t["a\0b"] = 1
    assert_equal 1, t["a\0b"]
    assert_equal 1, t.size
    assert_equal 0, t["a"]
  end

  def test_change_all_with_prefix
    default = 10
    t = Wordtriez.new default: default
    t['regexp'] = 1
    t['readme'] = 2
    t.change_all :prefix, 'readme' do |v|
      v += 4
    end
    assert_equal 'readme'.size + 1, t.size
    assert_equal 6, t['readme']
    assert_equal default + 4, t['read']
    assert_equal 1, t['regexp']
  end

  def test_change_all_with_suffix
    t = Wordtriez.new
    t['regexp'] = 1
    t['exp'] = 2
    t['reg'] = 3
    t.change_all :suffix, 'regexp' do |v|
      v += 4
    end
    assert_equal 5, t['regexp']
    assert_equal 6, t['exp']
    assert_equal 3, t['reg']
    assert_equal 'regexp'.size + 1, t.size
  end

  def test_change_all_with_substring
    t = Wordtriez.new value_type: :object
    t.change_all :substring, 'abc' do
      1
    end

    keys = []
    t.each do |k, v|
      keys << k
    end
    assert_equal %w[a b c ab bc abc].sort, keys.sort
  end

  def test_walk
    urls = %w[
      /users/
      /users/12/edit
      /posts
    ]
    t = Wordtriez.new value_type: :object
    urls.each_with_index do |url, i|
      t[url] = i.to_s
    end

    assert_equal [%w'/users/ 0'], t.walk('/users/12/delete').to_a
    assert_equal [%w'/users/ 0', %w'/users/12/edit 1'], t.walk('/users/12/edit').to_a
    assert_equal [%w'/users/ 0', %w'/users/12/edit 1'], t.walk('/users/12/edit/3').to_a

    assert_raise TypeError do
      t.walk :'/post' do
      end
    end

    t.walk '' do |k, v|
      assert_equal [nil, nil], [k, v]
    end

    # try to trigger rb_gc_mark(), it can stuck if hattrie_iter_next() not called properly
    100000.times{ 'a' + 'b' }
  end

  def test_solve_longest_common_substring
    sentences = %w[
      万塘路一锅鸡
      文二路一锅鸡
      来一锅鸡顶盒
      一锅鸡胗
    ]

    # value is bitset representing id of the sentence
    # in ruby we can use integers of arbitrary length as bitsets
    t = Wordtriez.new value_type: :object, default: 0

    sentences.each_with_index do |sentence, i|
      elem = 1 << i
      t.change_all :substring, sentence do |v|
        # union
        v | elem
      end
    end

    # longest common substring
    lcs = ''
    universe = (1 << sentences.size) - 1
    t.each do |k, v|
      lcs = k if (k.size > lcs.size and v == universe)
    end
    assert_equal '一锅鸡', lcs
  end

  def test_should_not_segfault_when_search
    t = Wordtriez.new
    # bursts when 16384
    16_385.times{ |i| t["a#{i}"] = i }
    expected_postfices = 16_385.times.map &:to_s
    actual_postfices = t.search("a").map(&:first)
    assert_equal expected_postfices.sort, actual_postfices.sort
  end
end
