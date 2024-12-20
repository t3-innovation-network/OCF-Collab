require 'test_helper'

class ContainerAssetFileFetcherTest < ActiveSupport::TestCase
  describe ContainerAssetFileFetcher do
    subject do
      ContainerAssetFileFetcher.new(
        container: container,
        access_token: access_token.token,
        requested_metamodel: requested_metamodel,
      )
    end

    let(:container) do
      create(:container, data_url:, node_directory:, external_id:)
    end

    let(:node_directory) do
      create(:node_directory, pna_url: pna_url)
    end

    let(:external_id) do
      "https://credentialengineregistry.org/resources/ce-001ef2e8-3f11-43b7-9adc-38801341c5b2"
    end

    let(:data_url) do
      "https://credentialengineregistry.org/graph/ce-001ef2e8-3f11-43b7-9adc-38801341c5b2"
    end

    let(:pna_url) do
      "http://example.com"
    end

    let(:access_token) do
      create(:access_token)
    end

    let(:expected_url) do
      [
        pna_url,
        "competency_frameworks/asset_file",
      ].join("/")
    end

    let(:expected_headers) do
      {
        "Authorization": "Bearer %s" % access_token.token,
      }
    end

    context "valid response" do
      before do
        stub_request(:get, expected_url).with(
          query: { id: data_url },
          headers: expected_headers
        ).to_return(pna_response)

      end

      let(:pna_response) do
        {
          body: pna_response_body,
          headers: pna_response_headers,
          status: 200,
        }
      end

      let(:pna_response_body) do
        "pna-response-body"
      end

      let(:pna_response_headers) do
        {
          "Content-Type" => "application/json"
        }
      end

      let(:metamodel_interchanger_init_mock) do
        mock = Minitest::Mock.new

        mock.expect(:call, metamodel_interchanger_mock) do |**args|
          assert_equal(
            {
              container:,
              container_body: pna_response_body,
              container_content_type: pna_response_headers["Content-Type"],
              requested_metamodel:
            },
            args
          )
        end

        mock
      end

      let(:metamodel_interchanger_mock) do
        mock = Minitest::Mock.new
        mock.expect(:transformed_body, metamodel_interchanger_transformed_body)
        mock.expect(:transformed_content_type, metamodel_interchanger_transformed_content_type)
        mock
      end

      let(:metamodel_interchanger_transformed_body) do
        "metmodel-interchanger-transformed-body"
      end

      let(:metamodel_interchanger_transformed_content_type) do
        "metmodel-interchanger-transformed-content-type"
      end

      context "without requested metamodel" do
        let(:requested_metamodel) do
          nil
        end

        describe ".body" do
          it "returns PNA response body" do
            ContainerMetamodelInterchanger.stub(:new, metamodel_interchanger_init_mock) do
              assert_equal pna_response_body, subject.body
            end
          end
        end

        describe ".content_type" do
          it "returns PNA response content type" do
            ContainerMetamodelInterchanger.stub(:new, metamodel_interchanger_init_mock) do
              assert_equal pna_response_headers["Content-Type"], subject.content_type
            end
          end
        end
      end

      context "with requested metamodel" do
        let(:requested_metamodel) do
          "metamodel-id"
        end

        describe ".body" do
          it "returns metamodel interchanger response body" do
            ContainerMetamodelInterchanger.stub(:new, metamodel_interchanger_init_mock) do
              assert_equal metamodel_interchanger_transformed_body, subject.body
            end
          end
        end

        describe ".content_type" do
          it "returns metamodel interchanger response content type" do
            ContainerMetamodelInterchanger.stub(:new, metamodel_interchanger_init_mock) do
              assert_equal metamodel_interchanger_transformed_content_type, subject.content_type
            end
          end
        end
      end
    end
  end
end
