require './bin/utils'

RSpec.describe Utils do
  describe '.convert_date' do
    it 'should return Date for common cases' do
      expect(Utils.convert_date("June 1")).to eq Date.new(Date.today.year, 6, 1)
    end

    it 'should return Date for formatted cases' do
      expect(Utils.convert_date("06/01/1958")).to eq Date.new(1958, 6, 1)
    end

    it 'should return TBA if input is TBA' do
      expect(Utils.convert_date("TBA")).to eq "TBA"
    end

    it 'should remove date ranges' do
      expect(Utils.convert_date("Oct 1-2")).to eq Date.new(Date.today.year, 10, 1)
    end
  end
end
