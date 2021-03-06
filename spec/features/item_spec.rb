  RSpec.feature "Item management", type: :feature do
  before do
    sign_in(@user)
  end
  let!(:url_prefix) { "/#{@organization.to_param}" }
  scenario "User creates a new item" do
    visit url_prefix + '/items/new'
    item_traits = attributes_for(:item)
    fill_in "Name", with: item_traits[:name]
    fill_in "Category", with: item_traits[:category]
    click_button "Create Item"

    expect(page.find('.alert')).to have_content "added"
  end

  scenario "User creates a new item with empty attributes" do
    visit url_prefix + '/items/new'
    item_traits = attributes_for(:item)
    click_button "Create Item"

    expect(page.find('.alert')).to have_content "didn't work"
  end

  scenario "User updates an existing item" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "Category", with: item.category + " new"
    click_button "Update Item"

    expect(page.find('.alert')).to have_content "updated"
  end

  scenario "User updates an existing item with empty attributes" do
    item = create(:item)
    visit url_prefix + "/items/#{item.id}/edit"
    fill_in "Name", with: ""
    click_button "Update Item"

    expect(page.find('.alert')).to have_content "didn't work"
  end

  scenario "User can filter the #index by category type" do
    Item.delete_all
    item = create(:item, category: "same")
    item2 = create(:item, category: "different")
    visit url_prefix + "/items"
    select Item.first.category, from: "filters_in_category"
    click_button "Filter"

    expect(page).to have_css("table tbody tr", count: 3)
  end

  scenario "Filters presented to user are alphabetized by category" do
    Item.delete_all
    item = create(:item, category: "same")
    item2 = create(:item, category: "different")
    expected_order = [item2.category, item.category]
    visit url_prefix + "/items"

    expect(page.all('select#filters_in_category option').map(&:text).select(&:present?)).to eq(expected_order)
    expect(page.all('select#filters_in_category option').map(&:text).select(&:present?)).not_to eq(expected_order.reverse)
  end

  describe "Item Table Tabs >" do
    before :each do
      # FIXME why isn't this handled by DatabaseCleaner?
      Item.delete_all
      InventoryItem.delete_all
      StorageLocation.delete_all
      @item = create(:item, name: "an item", category: "same")
      @item2 = create(:item, name: "another item", category: "different")
      @storage = create(:storage_location, :with_items, item: @item, item_quantity: 666, name: "Test storage")
      visit url_prefix + "/items"
    end
    # Consolidated these into one to reduce the setup/teardown
    scenario "Displays items in separate tabs", js: true do
      expect(page.find('table#tbl_items', visible: true)).not_to have_content "Quantity"
      expect(page.find(:css, 'table#tbl_items', visible: true)).to have_content(@item.name)
      expect(page).to have_selector('table#tbl_items tbody tr', count: 2)

      click_link "Items and Quantity" # href="#sectionB"
      expect(page.find('table#tbl_items_quantity', visible: true)).to have_content "Quantity"
      expect(page.find('table#tbl_items_quantity', visible: true)).not_to have_content "Test storage"
      expect(page.find('table#tbl_items_quantity', visible: true)).to have_content "666"
      expect(page).to have_selector('table#tbl_items_quantity tbody tr', count: 2)

      click_link "Items, Quantity, and Location" # href="#sectionC"
      expect(page.find('table#tbl_items_location', visible: true)).to have_content "Quantity"
      expect(page.find('table#tbl_items_location', visible: true)).to have_content "Test storage"
      expect(page.find('table#tbl_items_location', visible: true)).to have_content "666"

      # FIXME -- this should be 2. It's 3 because an unnecessary TR is being created.
      expect(page).to have_selector('table#tbl_items_location tbody tr', count: 3)
    end
  end
end
