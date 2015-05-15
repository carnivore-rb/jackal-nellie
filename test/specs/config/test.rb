Configuration.new do

  jackal do
    require [
      "carnivore-actor",
      "jackal-code-fetcher",
      "jackal-nellie"
    ]

    assets do
      connection do
        provider 'local'
        credentials do
          object_store_root '/tmp/jackal-assets'
        end
      end
      bucket 'code-fetcher'
    end

    code_fetcher do
      config { working_directory '/tmp/jackal-code-fetcher' }

      sources do
        input  { type 'actor' }
        output { type 'spec' }
      end

      callbacks [ "Jackal::CodeFetcher::GitHub" ]
    end

    nellie do
      config { working_directory '/tmp/nellie' }

      sources do
        input  { type 'actor' }
        output { type 'spec' }
      end

      callbacks [ "Jackal::Nellie::Processor" ]
    end

  end

end
