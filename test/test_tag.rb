require File.dirname(__FILE__) + '/helper'

class TestTag < Test::Unit::TestCase
  def setup
    @r = Repo.new(File.join(File.dirname(__FILE__), *%w[dot_git]), :is_bare => true)
  end


  # create

  def test_create_tag
    @r.add_tag 'test/with_slash'
    tag = @r.tags.find { |t| t.name == 'test/with_slash' }
    @r.git.tag({:d => true}, 'test/with_slash')
    assert_instance_of Grit::Tag, tag
  end
  def test_create_tag_from_default
    tag = @r.add_tag 'test_from_default'
    @r.git.tag({:d => true}, 'test_from_default')
    assert_equal @r.branch('master').commit, tag.commit
  end

  def assert_tag_created_from(tag_name, nonpack_startpoint)
    tag = @r.add_tag tag_name, nonpack_startpoint
    @r.git.tag({:d => true}, tag_name) # clean up

    assert_equal @r.branch('nonpack').commit, tag.commit,
        "expected #{ tag_name } to start from #{ nonpack_startpoint }"
  end

  def test_create_tag_from_ref
    assert_tag_created_from 'test_from_ref', @r.branch('nonpack')
  end
  def test_create_tag_from_commit
    assert_tag_created_from 'test_from_commit', @r.branch('nonpack').commit
  end
  def test_create_tag_from_string
    assert_tag_created_from 'test_from_string', 'nonpack'
  end
  def test_create_tag_from_sha1
    assert_tag_created_from 'test_from_sha1', @r.branch('nonpack').commit.id
  end

  # list_from_string size

  def test_list_from_string_size
    assert_equal 5, @r.tags.size
  end

  # list_from_string

  def test_list_from_string
    tag = @r.tags[1]

    assert_equal 'not_annotated', tag.name
    assert_equal 'ca8a30f5a7f0f163bbe3b6f0abf18a6c83b0687a', tag.commit.id
  end

  # list_from_string_for_signed_tag

  def test_list_from_string_for_signed_tag
    tag = @r.tags[2]

    assert_equal 'v0.7.0', tag.name
    assert_equal '7bcc0ee821cdd133d8a53e8e7173a334fef448aa', tag.commit.id
  end

  # list_from_string_for_annotated_tag

  def test_list_from_string_for_annotated_tag
    tag = @r.tags.first

    assert_equal 'annotated', tag.name
    assert_equal 'ca8a30f5a7f0f163bbe3b6f0abf18a6c83b0687a', tag.commit.id
  end

  # list_from_string_for_packed_tag

  def test_list_from_string_for_packed_tag
    tag = @r.tags[4]

    assert_equal 'packed', tag.name
    assert_equal 'ca8a30f5a7f0f163bbe3b6f0abf18a6c83b0687a', tag.commit.id
  end

  # list_from_string_for_packed_annotated_tag

  def test_list_from_string_for_packed_annotated_tag
    tag = @r.tags[3]

    assert_equal 'packed_annotated', tag.name
    assert_equal '7bcc0ee821cdd133d8a53e8e7173a334fef448aa', tag.commit.id
  end


  # inspect

  def test_inspect
    tag = @r.tags.last

    assert_equal %Q{#<Grit::Tag "#{tag.name}">}, tag.inspect
  end
end
