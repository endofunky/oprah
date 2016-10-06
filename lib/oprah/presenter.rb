module Oprah
  class Presenter < SimpleDelegator
    # @return [ActionView::Base] The view context
    attr_reader :view_context

    alias :h :view_context

    # @!visibility private
    @@cache = ActiveSupport::Cache::MemoryStore.new

    class << self
      # Returns the shared presenter cache object.
      #
      # @return [ActiveSupport::Cache::MemoryStore]
      def cache
        @@cache
      end

      # Presents the given `object` with all it's matching presenters,
      # following it's ancestors in reverse.
      #
      # @param object [Object] The object to present
      # @param view_context [ActionView::Context] View context to assign
      # @param only [Class] Class or Array of presenters to use
      # @return [Presenter] Presented object
      def present(object, view_context: default_view_context, only: nil)
        presenters = presenter_classes_for(object)
        presenters &= Array(only) if only

        presenters.inject(object) do |memo, presenter|
          presenter.new(memo, view_context: view_context)
        end
      end

      # Presents the given `objects` with all their matching presenters.
      # The behaviour and parameters are identical to `.present`'s.
      #
      # @param objects [Enumerable] The objects to present
      # @see .present
      def present_many(objects, **kwargs)
        objects.map { |object| present(object, **kwargs) }
      end

      # Automatically wrap the objects returned by the given one-to-one
      # `association` method in presenters.
      #
      # Presenters will re-use the parent's assigned view context.
      #
      # @param association [Symbol] Name of the association
      # @return [Symbol] Name of the association
      def presents_one(association)
        define_method association do
          present(__getobj__.__send__(association))
        end

        association
      end

      # Automatically wrap the objects returned by the given one-to-many
      # or many-to-many `association` method in presenters.
      #
      # Presenters will re-use the parent's assigned view context.
      #
      # @param association [Symbol] Name of the association
      # @return [Symbol] Name of the association
      def presents_many(association)
        define_method association do
          present_many(__getobj__.__send__(association))
        end

        association
      end

      # Returns the default view context to use if no view context is explicitly
      # passed to the presenter.
      #
      # @return [ActionView::Context]
      def default_view_context
        ActionController::Base.new.view_context
      end

      private

      # @since 0.2.0
      def presenter_classes_for(object)
        klass = object.class

        @@cache.fetch klass.name do
          klass.ancestors.map do |ancestor|
            next unless ancestor.name
            (ancestor.name + "Presenter").safe_constantize
          end.compact.reverse
        end
      end
    end

    # Initializes a new Presenter.
    #
    # @param object [Object] The object to present
    # @param view_context [ActionView::Context] View context to assign
    def initialize(object, view_context: self.class.default_view_context)
      __setobj__(object)
      @view_context = view_context
    end

    # Presents a single object.
    #
    # Will re-use the presenter's assigned view context if no `view_context`:
    # parameter is given.
    #
    # @see .present
    def present(*args, **kwargs, &block)
      kwargs = { view_context: view_context }.merge(kwargs)
      self.class.present(*args, **kwargs, &block)
    end

    # Presents a collection of objects.
    #
    # Will re-use the presenter's assigned view context if no `view_context`:
    # parameter is given.
    #
    # @see .present_many
    def present_many(*args, **kwargs, &block)
      kwargs = { view_context: view_context }.merge(kwargs)
      self.class.present_many(*args, **kwargs, &block)
    end

    # Returns true if `klass` is the class of the presented object or the
    # presenter, or if `#class` is one of the superclasses of the presented
    # object, the presenter or modules included in the presented object or the
    # presenter.
    #
    # @param other [Module]
    # @return [Boolean] result
    def kind_of?(other)
      super || __getobj__.kind_of?(other)
    end

    alias :is_a? :kind_of?

    # Returns `true` if the presented object or the presenter is an instance
    # of the given `class`.
    #
    # @param klass [Class]
    # @return [Boolean] result
    def instance_of?(klass)
      super || __getobj__.instance_of?(klass)
    end
  end
end
