module Oprah
  class Presenter
    extend Forwardable

    # @return [Object] The presented object
    attr_reader :object

    # @return [ActionView::Base] The view context
    attr_reader :view_context

    alias :h :view_context

    # @!visibility private
    @@cache = ActiveSupport::Cache::MemoryStore.new

    # @!method inspect
    #   @see Object#inspect
    #   @return [String]
    # @!method to_s
    #   @see Object#to_s
    #   @return [String]
    def_delegators :@object, :inspect, :to_s

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
      # @return [Boolean]
      def presents_one(association)
        define_method association do
          present(object.__send__(association), view_context: view_context)
        end
      end

      # Automatically wrap the objects returned by the given one-to-many
      # or many-to-many `association` method in presenters.
      #
      # Presenters will re-use the parent's assigned view context.
      #
      # @param association [Symbol] Name of the association
      # @return [Boolean]
      def presents_many(association)
        define_method association do
          present_many(object.__send__(association), view_context: view_context)
        end

        true
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
          klass.ancestors.map do |klass|
            (klass.name + "Presenter").safe_constantize if klass.name
          end.compact.reverse
        end
      end
    end

    # Initializes a new Presenter.
    #
    # @param object [Object] The object to present
    # @param view_context [ActionView::Context] View context to assign
    def initialize(object, view_context: self.class.default_view_context)
      @object = object
      @view_context = view_context
    end

    # Delegates all method calls not handled by the presenter to `object`.
    def method_missing(meth, *args, &block)
      if respond_to?(meth)
        object.__send__(meth, *args, &block)
      else
        super
      end
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

    # Returns true if either `object` or `self` responds to the given method
    # name.
    #
    # @param method [Symbol] Name of the method
    # @param include_private [Boolean] Whether to include private methods
    # @return [Boolean] result
    def respond_to?(method, include_private = false)
      super || object.respond_to?(method, include_private)
    end

    # Returns true if `klass` is the class of `object` or the presenter, or
    # if `#class` is one of the superclasses of `object`, the presenter or
    # modules included in `object` or the presenter.
    #
    # @param other [Module]
    # @return [Boolean] result
    def kind_of?(other)
      super || object.kind_of?(other)
    end

    alias :is_a? :kind_of?

    # Returns `true` if `object` or the presenter is an instance of the given
    # `class`.
    #
    # @param klass [Class]
    # @return [Boolean] result
    def instance_of?(klass)
      super || object.instance_of?(klass)
    end

    # Returns `true` if `object` or the presenter tests positive for equality.
    #
    # @param other [Object]
    # @return [Boolean] result
    def ==(other)
      super || object == other
    end
  end
end
