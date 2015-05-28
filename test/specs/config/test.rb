Configuration.new do

  jackal do
    require [
      "carnivore-actor",
      "jackal-nellie"
    ]

    assets do
      connection do
        provider 'local'
        credentials do
          object_store_root '/tmp/jackal-assets'
        end
      end
      bucket 'nellie'
    end

    nellie do
      config do
        script_name 'NELLIE'
        working_directory '/tmp/nellie'
      end

      sources do
        input  { type 'actor' }
        output { type 'spec' }
      end

      callbacks [ "Jackal::Nellie::Processor" ]
    end

  end

end
