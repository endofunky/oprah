require 'helper'

module Oprah
  class PresenterTest < Minitest::Test
    include Fixtures

    def test_cache
      assert_kind_of ActiveSupport::Cache::MemoryStore, Presenter.cache
      assert_equal Presenter.cache, Presenter.cache
      assert_equal UserPresenter.cache, Presenter.cache
    end

    def test_present
      assert_presented present(User.new)
    end

    def test_present_no_matching_presenter
      object = Object.new
      presented = present(object)

      refute_presented presented
      assert_equal presented, object
    end

    def test_present_only
      presenter = present(User.new, only: UserPresenter)

      assert_kind_of UserPresenter, presenter
      refute_kind_of EntityPresenter, presenter

      classes = [UserPresenter, EntityPresenter, CommentPresenter]
      presenter = present(User.new, only: classes)

      assert_kind_of UserPresenter, presenter
      assert_kind_of EntityPresenter, presenter
      refute_kind_of CommentPresenter, presenter
    end

    def test_present_many
      present_many([User.new, User.new]).each do |presenter|
        assert_equal "Foo Bar", presenter.name
      end
    end

    def test_presents_many
      project = present(Project.new)

      assert_equal 3, project.comments.length

      project.comments.each do |comment|
        assert_kind_of Comment, comment
        assert_kind_of CommentPresenter, comment
      end
    end

    def test_present_from_instance
      view_context = Object.new
      presenter = present(User.new, view_context: view_context)
      presented = presenter.present(User.new)

      assert_equal view_context.object_id, presented.view_context.object_id
    end

    def test_present_many_from_instance
      view_context = Object.new
      presenter = present(User.new, view_context: view_context)
      presented = presenter.present_many([User.new]).first

      assert_equal view_context.object_id, presented.view_context.object_id
    end

    def test_present_from_instance_custom_view_context
      view_context = Object.new
      presenter = present(User.new, view_context: view_context)
      presented = presenter.present(User.new, view_context: :ok)

      assert_equal :ok, presented.view_context
    end

    def test_present_many_from_instance_custom_view_context
      view_context = Object.new
      presenter = present(User.new, view_context: view_context)
      presented = presenter.present_many([User.new], view_context: :ok).first

      assert_equal :ok, presented.view_context
    end

    def test_presents_one
      project = present(Project.new)
      owner = project.owner

      assert_kind_of UserPresenter, owner
      assert_kind_of User, owner
    end

    def test_presenter_stack_ordering
      assert_equal "foobar", present(User.new).foo
    end

    def test_present_eigenclass
      klass = Struct.new(:name)
      klass.define_singleton_method(:hi) {"foobar"}
      assert_equal "foobar", present(klass).hi
    end

    def test_default_view_context_using_present
      presenter = Presenter.present(User.new)
      assert_kind_of ActionView::Context, presenter.view_context
    end

    def test_default_view_context_using_initialize
      presenter = UserPresenter.new(User.new)
      assert_kind_of ActionView::Context, presenter.view_context
    end

    def test_default_view_context_unique_per_presenter
      refute_equal present(User.new).view_context,
                   present(User.new).view_context
    end

    def test_method_missing_delegation
      assert_equal "Foo Bar", present(User.new).name
      assert_equal "Foo", present(User.new).first_name
      assert_equal "Bar", present(User.new).last_name
    end

    def test_method_missing_wont_delegate_to_private_methods
      assert_raises NoMethodError do
        present(User.new).password
      end
    end

    def test_kind_of?
      presenter = present(User.new)

      assert_kind_of User, presenter
      assert_kind_of UserPresenter, presenter
      assert_kind_of Entity, presenter
      assert_kind_of EntityPresenter, presenter
      refute_kind_of self.class, presenter
    end

    def test_instance_of?
      presenter = present(User.new)

      assert_instance_of User, presenter
      assert_instance_of UserPresenter, presenter
      refute_instance_of Entity, presenter
      assert_instance_of EntityPresenter, presenter
      refute_instance_of self.class, presenter
    end

    def test_equality
      project = Project.new
      project_presenter = Project.new

      user = User.new
      user_presenter = present(user)

      assert_equal user_presenter, user
      assert_equal user_presenter, user_presenter
      refute_equal user_presenter, project
      refute_equal user_presenter, project_presenter
    end

    def test_inspect
      user = User.new
      presenter = present(user)

      assert_equal user.inspect, presenter.inspect
    end

    def test_to_s
      user = User.new
      presenter = present(user)

      assert_equal user.to_s, presenter.to_s
    end
  end
end
