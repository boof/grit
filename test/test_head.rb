require File.dirname(__FILE__) + '/helper'

class TestHead < Test::Unit::TestCase
  def setup
    @r = Repo.new(File.join(File.dirname(__FILE__), *%w[dot_git]), :is_bare => true)
  end

  # create

  def test_create_head
    returned_head = @r.branch 'test/create_head'
    found_head = @r.heads.find { |h| h.name == 'test/create_head' }
    @r.git.branch({:d => true}, 'test/create_head')
    assert_instance_of Grit::Head, returned_head
    assert_equal returned_head, found_head
  end

  def test_in_branch_commits_index
    @r = Repo.init "#{ File.join File.dirname(__FILE__), 'not_bare' }"

    expect_message = 'This is a test...'
    path = File.join @r.working_dir, 'in_branch'
    File.open(path, 'w') { |f| f << expect_message }

    commit = @r.branch('test/in_branch').
        in_branch(expect_message) { |r| r.add path }

    assert_equal expect_message, commit.message
  ensure
    FileUtils.rm_r @r.working_dir if File.exists? @r.working_dir
  end

  # inspect

  def test_inspect
    head = @r.heads[1]
    assert_equal %Q{#<Grit::Head "test/master">}, head.inspect
  end

  def test_master
    head = @r.commit('master')
    assert_equal 'ca8a30f5a7f0f163bbe3b6f0abf18a6c83b0687a', head.id
  end

  def test_submaster
    head = @r.commit('test/master')
    assert_equal '2d3acf90f35989df8f262dc50beadc4ee3ae1560', head.id
  end
  
  # heads with slashes

  def test_heads_with_slashes
    head = @r.heads[3]
    assert_equal %Q{#<Grit::Head "test/chacon">}, head.inspect
  end
  
  def test_is_head
    assert @r.is_head?('master')
    assert @r.is_head?('test/chacon')
    assert !@r.is_head?('masterblah')
  end

  def test_head_count
    assert_equal 5, @r.heads.size
  end


  def test_nonpack
    assert @r.heads.map { |h| h.name }.include?('nonpack')
  end

end
