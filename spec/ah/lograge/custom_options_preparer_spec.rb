describe Ah::Lograge::CustomOptionsPreparer do
  # The real trick here is that Tempfile is trying to serialize it's contents
  # this test is about if we catch UploadedFIle and generate it's json manually
  describe '#serializable?' do
    let(:crazy_character) { "\x89".force_encoding('ASCII-8BIT') }
    let(:tempfile) { Tempfile.new('uploaded_file').tap { |f| f.write(crazy_character); f.seek(0) } }
    let(:params) do
      {
        attachment: ActionDispatch::Http::UploadedFile.new(
          tempfile: tempfile, filename: "some_temp_file.ext", type: "text/plain"
        )
      }
    end
    it 'forces params to be serializable' do
      expect(described_class.serializable?(params)).to be_truthy
      expect{ params.to_json }.not_to raise_exception
      expect(params).to eq(
        attachment: {
           type: "ActionDispatch::Http::UploadedFile",
           name: "some_temp_file.ext",
           size: 1,
           content_type: "text/plain"
        }
      )
    end
    describe 'bad encoded file name' do
      let(:params) do
        {
          attachment: ActionDispatch::Http::UploadedFile.new(
            tempfile: tempfile, filename: "some_temp_file#{ crazy_character }.ext", type: "text/plain"
          )
        }
      end
      specify do
        expect(described_class.serializable?(params)).to be_truthy
        expect(params[:attachment][:name]).to eq('some_temp_file?.ext')
      end
    end
    describe 'ActionController::Parameters' do
      let(:params) { ActionController::Parameters.new(super()) }
      specify do
        expect(described_class.serializable?(params)).to be_truthy
        expect(params).to be_kind_of(ActionController::Parameters)
        expect { params.to_json }.not_to raise_exception
      end
    end
  end
end
