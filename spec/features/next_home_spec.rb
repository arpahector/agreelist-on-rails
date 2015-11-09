require 'spec_helper'

feature 'next home' do
  before do
    6.times{ create(:statement) }
    create(:statement, content: "Should the UK remain a member of the EU?")
  end

  scenario 'vote' do
    visit home_path
    click_link "Agree"
    fill_in "email", with: "hi@hectorperezarenas.com"
    click_button "See results"
    expect(page).to have_content("Should the UK remain a member of the EU?")
  end
end
