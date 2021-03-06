require "spec_helper"

describe Api::Stats::Tps::DossiersController, type: :controller do
  before do
    stub_request(:get, "https://tps.apientreprise.fr/api/statistiques/dossiers").
        to_return(:status => 200, :body => '{"total":330,"mois":90}', :headers => {})
  end

  subject { JSON.parse(response.body) }

  describe "GET index" do
    before do
      get :index
    end

    it { expect(response.status).to eq 200 }
  end
end