module ResourceUtilsSpecHelper
  def self.sorted_hash_2_level
    {
        a: '1',
        b: '2',
        c: {
            a: '1',
            b: '2',
            c: '3'
        }
    }
  end

  def self.sorted_hash_3_level
    {
        a: '1',
        b: '2',
        c: {
            a: '1',
            b: '2',
            c: {
                a: '1',
                b: '2',
                c: '3'
            }
        }
    }
  end

  def self.unsorted_hash_2_level
    {
        c: {
            c: '3',
            a: '1',
            b: '2'
        },
        a: '1',
        b: '2'
    }
  end

  def self.unsorted_hash_3_level
    {
        c: {
            c: {
                c: '3',
                a: '1',
                b: '2',
            },
            a: '1',
            b: '2'
        },
        a: '1',
        b: '2'
    }
  end
end