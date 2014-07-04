require 'spec_helper'

describe RegisterableRouteSet do
  describe '.from_content_item' do
    it "constructs a route set from a non-redirect content item" do
      item = build(:content_item, :base_path => "/path", :rendering_app => "frontend")
      item.routes = [
        { 'path' => '/path', 'type' => 'exact'},
        { 'path' => '/path.json', 'type' => 'exact'},
        { 'path' => '/path/subpath', 'type' => 'prefix'},
      ]
      route_set = RegisterableRouteSet.from_content_item(item)
      expect(route_set.is_redirect).to be_false
      expected_routes = [
        RegisterableRoute.new(:path => '/path',         :type => 'exact',  :rendering_app => 'frontend'),
        RegisterableRoute.new(:path => '/path.json',    :type => 'exact',  :rendering_app => 'frontend'),
        RegisterableRoute.new(:path => '/path/subpath', :type => 'prefix', :rendering_app => 'frontend'),
      ]
      expect(route_set.registerable_routes).to match_array(expected_routes)
      expect(route_set.registerable_redirects).to eq([])
    end

    it "constructs a route set from a redirect content item" do
      item = build(:redirect_content_item, :base_path => "/path")
      item.redirects = [
        { "path" => "/path", "type" => 'exact', "destination" => "/somewhere" },
        { "path" => "/path/foo", "type" => "prefix", "destination" => "/somewhere-else" },
      ]

      route_set = RegisterableRouteSet.from_content_item(item)
      expect(route_set.is_redirect).to be_true
      expect(route_set.registerable_routes).to eq([])
      expected_redirects = [
        RegisterableRedirect.new(:path => "/path", :type => "exact", :destination => "/somewhere"),
        RegisterableRedirect.new(:path => "/path/foo", :type => "prefix", :destination => "/somewhere-else"),
      ]
      expect(route_set.registerable_redirects).to match_array(expected_redirects)
    end
  end

  describe "validations" do
    context "for a non-redirect item" do
      before :each do
        @route_set = build(:registerable_route_set, :is_redirect => false)
      end

      it 'is valid with a valid set of registerable routes' do
        @route_set.registerable_routes = [
          RegisterableRoute.new(:path => "#{@route_set.base_path}", :type => 'exact',  :rendering_app => 'frontend'),
          RegisterableRoute.new(:path => "#{@route_set.base_path}.json", :type => 'exact',  :rendering_app => 'frontend'),
          RegisterableRoute.new(:path => "#{@route_set.base_path}/exact-subpath", :type => 'exact', :rendering_app => 'frontend'),
          RegisterableRoute.new(:path => "#{@route_set.base_path}/sub/path-prefix", :type => 'prefix', :rendering_app => 'frontend'),
        ]
        expect(@route_set).to be_valid
      end

      it "requires some routes" do
        @route_set.registerable_routes = []
        expect(@route_set).not_to be_valid
      end

      it "requires all routes to be valid" do
        @route_set.registerable_routes.first.type = "not_a_valid_type"
        expect(@route_set).not_to be_valid
      end

      it "requires any redirects to be valid"

      it "requires all routes to be beneath the base path" do
        @route_set.registerable_routes << build(:registerable_route, :path => "/another-path")
        expect(@route_set).not_to be_valid

        # string prefix of base_path is not under the base path.
        @route_set.registerable_routes.last.path = "#{@route_set.base_path}-foo"
        expect(@route_set).not_to be_valid
      end

      it "requires any redirects to be beneath the base path"

      it "requires the routes to include the base path" do
        @route_set.registerable_routes.first.path = "#{@route_set.base_path}/foo"
        expect(@route_set).to_not be_valid
      end
    end

    context "for a redirect item" do
      before :each do
        @route_set = build(:registerable_route_set, :is_redirect => true)
      end

      it 'is valid with a valid set of registerable redirects' do
        @route_set.registerable_redirects = [
          RegisterableRedirect.new(:path => "#{@route_set.base_path}", :type => 'exact', :destination => "/somewhere"),
          RegisterableRedirect.new(:path => "#{@route_set.base_path}.json", :type => 'exact', :destination => "/somewhere"),
          RegisterableRedirect.new(:path => "#{@route_set.base_path}/exact-subpath", :type => 'exact', :destination => "/somewhere"),
          RegisterableRedirect.new(:path => "#{@route_set.base_path}/sub/path-prefix", :type => 'prefix', :destination => "/somewhere"),
        ]
        expect(@route_set).to be_valid
      end

      it "requires no routes to be present" do
        @route_set.registerable_routes = [build(:registerable_route, :path => @route_set.base_path)]
        expect(@route_set).not_to be_valid
      end

      it "requires all redirects to be valid" do
        @route_set.registerable_redirects.first.type = "not_a_valid_type"
        expect(@route_set).not_to be_valid
      end

      it "requires all redirects to be beneath the base path" do
        @route_set.registerable_redirects << build(:registerable_redirect, :path => "/another-path")
        expect(@route_set).not_to be_valid

        # string prefix of base_path is not under the base path.
        @route_set.registerable_redirects.last.path = "#{@route_set.base_path}-foo"
        expect(@route_set).not_to be_valid
      end

      it "requires the redirects to include the base path" do
        @route_set.registerable_redirects.first.path = "#{@route_set.base_path}/foo"
        expect(@route_set).to_not be_valid
      end
    end
  end

  describe '#register!' do
    before do
      @routes = [
        build(:registerable_route, :path => '/path', :type => 'exact', :rendering_app => 'frontend'),
        build(:registerable_route, :path => '/path/sub/path', :type => 'prefix', :rendering_app => 'frontend'),
      ]
      @route_set = RegisterableRouteSet.new(:registerable_routes => @routes, :base_path => '/path', :rendering_app => 'frontend')
      @route_set.register!
    end

    it 'registers and commits all registeragble routes' do
      assert_routes_registered('frontend', [
        ['/path', 'exact'],
        ['/path/sub/path', 'prefix']
      ])
    end
  end
end
