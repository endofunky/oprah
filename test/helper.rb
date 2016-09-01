require 'minitest/autorun'
require 'minitest/pride'
require 'oprah'
require 'oprah/railtie'
require 'oprah/test_helpers'
require 'dummy/init'

class Minitest::Test
  include Oprah::TestHelpers

  def setup
    super
    Oprah::Presenter.cache.clear
  end
end

module Fixtures
  module Entity
  end

  class EntityPresenter < Oprah::Presenter
    def foo
      "foo"
    end
  end

  class User
    include Entity

    def first_name
      "Foo"
    end

    def last_name
      "Bar"
    end

    private

    def password
      "baz"
    end
  end

  class UserPresenter < Oprah::Presenter
    def name
      [first_name, last_name].join(' ')
    end

    def foo
      super + "bar"
    end
  end

  class Comment
  end

  class CommentPresenter < Oprah::Presenter
  end

  class Project
    def comments
      Array.new(3) { Comment.new }
    end

    def owner
      User.new
    end
  end

  class ProjectPresenter < Oprah::Presenter
    presents_many :comments
    presents_one :owner
  end

  module KotakDocument
    def self.included(am_bas)
      am_bas.extend ClassMethods
    end

    module ClassMethods
      def field(name)
        generated_fields.module_eval do
          define_method(name) { name.to_s.upcase }
        end
      end

      # From
      #  https://github.com/mongodb/mongoid/blob/6.0-contexts/lib/mongoid/fields.rb#L540
      def generated_fields
        @generated_fields ||= begin
          mod = Module.new
          include(mod)
          mod
        end
      end
    end
  end

  # Instance of this class will have eigenclass in the ancestors.
  #
  # Example:
  #   > doc = EigenKotak.new
  #   > doc.class.ancestors
  #      => [Fixtures::EigenKotak, #<Module:0x007f927cbde370>,
  #   > doc.class.ancestors.map(&:name)
  #      => ["Fixtures::EigenKotak", nil, "Fixtures::KotakDocument", ...
  #
  class EigenKotak
    include KotakDocument
    field :name
  end

end
