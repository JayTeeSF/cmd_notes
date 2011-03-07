# Orig - no optimization
def update_modified_external_data_by_something_else(something_else, etc)
    # ...
    diff = External.scope.map(&:attr) - something_else * etc
    # ...
end

# Draft 1 - optimization w/ "bug".
# Reminder: Anytime there's caching, "flushing" will eventually be required
def modified_external_data
  @modified_external_data ||= External.scope.map(&:attr)
end

def update_modified_external_data_by_something_else(something_else, etc)
    # ...
    diff = modified_external_data - something_else * etc
    # ...
end

# Draft 2 # even though I *knew* it was gross, but was hunting down the "bug"

def modified_external_data_cache_on


# Draft 3 # after realizing I shouldn't just pass some optional-param to the update... method
# why? (Eric Evans would tell you) it's not part of that method's contract

module MyModule
  def modified_external_data
    return @modified_external_data if @modified_external_data
    External.scop.map(&:attr)
  end

  def modified_external_data_cache_on
    @modified_external_data = External.scope.map(&:attr)
  end

  # default
  def modified_external_data_cache_off
    @modified_external_data = nil
  end

  def update_modified_external_data_by_something_else(something_else, etc)
      # ...
      diff = modified_external_data - something_else * etc
      # ...
  end

  # rake task - bulk activity
  def populate_all_modified_external_data_aspects(verbose = false)
    modified_external_data_cache_on
    out = verbose ? STDOUT : File.open('/dev/null', 'w')
    pbar = ProgressBar.new("ExternalData Activity", (Aspect.count), out)

    Aspect.find_each do |aspect|
      attr_objs = aspect.map(&:attr)
      MyModule.update_modified_external_data_by_something_else(attr_objs, aspect)
      pbar.inc(1)
    end

    pbar.finish
    modified_external_data_cache_off
  end

end

# final
def with_cached_monster_location_ids(&block)
  @monster_location_lids = monster_location_lids
  yield
  @monster_location_lids = nil
end

def populate_all_monster_location_offers(verbose = false)
  with_cached_monster_location_ids do
    stuff...
  end
end
