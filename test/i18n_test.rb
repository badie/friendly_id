require File.expand_path("../helper.rb", __FILE__)

class I18nTest < MiniTest::Unit::TestCase
  include FriendlyId::Test

  class Journalist < ActiveRecord::Base
    extend FriendlyId
    friendly_id :name, :use => :simple_i18n
  end

  test "friendly_id should return a the current locale's slug" do
    journalist = Journalist.new(:name => "John Doe")
    journalist.slug_es = "juan-fulano"
    journalist.valid?
    I18n.with_locale(I18n.default_locale) do
      assert_equal "john-doe", journalist.friendly_id
    end
    I18n.with_locale(:es) do
      assert_equal "juan-fulano", journalist.friendly_id
    end
  end

  test "should create record with slug in column for the current locale" do
    I18n.with_locale(I18n.default_locale) do
      journalist = Journalist.new(:name => "John Doe")
      journalist.valid?
      assert_equal "john-doe", journalist.slug_en
      assert_nil journalist.slug_es
    end
    I18n.with_locale(:es) do
      journalist = Journalist.new(:name => "John Doe")
      journalist.valid?
      assert_equal "john-doe", journalist.slug_es
      assert_nil journalist.slug_en
    end
  end

  test "to_param should return the numeric id when there's no slug for the current locale" do
    transaction do
      journalist = Journalist.new(:name => "Juan Fulano")
      I18n.with_locale(:es) do
        journalist.save!
        assert_equal "juan-fulano", journalist.to_param
      end
      assert_equal journalist.id.to_s, journalist.to_param
    end
  end

  test "should set friendly id for locale" do
    transaction do
      journalist = Journalist.create!(:name => "John Smith")
      journalist.set_friendly_id("Juan Fulano", :es)
      journalist.save!
      assert_equal "juan-fulano", journalist.slug_es
      I18n.with_locale(:es) do
        assert_equal "juan-fulano", journalist.to_param
      end
    end
  end

  test "should sequence localized slugs" do
    transaction do
      journalist = Journalist.create!(:name => "John Smith")
      I18n.with_locale(:es) do
        Journalist.create!(:name => "Juan Fulano")
      end
      journalist.set_friendly_id("Juan Fulano", :es)
      journalist.save!
      assert_equal "john-smith", journalist.to_param
      I18n.with_locale(:es) do
        assert_equal "juan-fulano--2", journalist.to_param
      end
    end
  end

  class RegressionTest < MiniTest::Unit::TestCase
    include FriendlyId::Test

    test "should not overwrite slugs on update_attributes" do
      transaction do
        journalist = Journalist.create!(:name => "John Smith")
        journalist.set_friendly_id("Juan Fulano", :es)
        journalist.save!
        assert_equal "john-smith", journalist.to_param
        journalist.update_attributes :name => "Johnny Smith"
        assert_equal "johnny-smith", journalist.to_param
        I18n.with_locale(:es) do
          assert_equal "juan-fulano", journalist.to_param
        end
      end
    end
  end

  class ConfigurationTest < MiniTest::Unit::TestCase
    test "should add locale to slug column for a non-default locale" do
      I18n.with_locale :es do
        assert_equal "slug_es", Journalist.friendly_id_config.slug_column
      end
    end

    test "should add locale to non-default slug column and non-default locale" do
      model_class = Class.new(ActiveRecord::Base) do
        extend FriendlyId
        friendly_id :name, :use => :simple_i18n, :slug_column => :foo
      end
      I18n.with_locale :es do
        assert_equal "foo_es", model_class.friendly_id_config.slug_column
      end
    end

    test "should add locale to slug column for default locale" do
      I18n.with_locale(I18n.default_locale) do
        assert_equal "slug_en", Journalist.friendly_id_config.slug_column
      end
    end
  end
end
