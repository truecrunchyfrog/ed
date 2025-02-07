# ED
Välkommen till ED!

Det här programmets uppgift är att:
* ta emot en lista med information om företag och arbetsgivare,
* hämta information om företagen, och med hjälp av en LLM, generera ett passande e-postmeddelande och
* skicka iväg brevet till arbetsgivaren.

# Miljövariabler

## `DATA`

`DATA` (arbetsgivarlistan) är en JSON-lista med följande format:

```json
{
    "name": "John Doe",
    "email": "john.doe@example.com",
    "company": "Sprängämnen AB",
    "website": "https://example.com"
}
```

## `ENTRIES`

`ENTRIES` är namnet på en CSV-fil. Filen representerar de arbetsgivare som programmet har sökt.
Filen kan användas till LIA-ansökningsprocessrepresentationen.
Programmet läser och skriver till filen.
För varje företagsiteration från `DATA`, ignoreras de som listas här (baserat på e-postadress), för att inte skicka flera ansökningar till samma plats, om man kör programmet flera gånger.
När en ansökning på ett företag görs, skrivs en rad till den här filen.

CSV-filens format är:
```csv
Företagsnamn,Kontaktperson,E-postadress,Datum
```

## `GENERATION_EXPRESSION`

`GENERATION_EXPRESSION` är ett Ruby-uttryck som ska generera ett object (hash) i formatet:

```ruby
{
    :subject => 'Jag söker LIA!!!!',
    :content => 'LIA sökes blablabla...'
}
```

Uttrycket exponeras till en objekt-variabel `data` i formatet:

```ruby
{
    :name => 'John Doe',
    :email => 'john.doe@example.com',
    :company => 'Sprängämnen AB',
    :company_info => 'Vi på Sprängämnen AB tror på innovation, och så vidare.' # Hämtat från webbsida. Mata in i LLM.
}
```

## `MAIL_SEND`

`MAIL_SEND` är ett Ruby-uttryck som tar emot information för att skicka ett e-postmeddelande, och ska sedan utföra det.

Uttrycket exponeras till en objekt-variabel `data` i formatet:

```ruby
{
    :email => 'john.doe@example.com',
    :subject => 'Jag söker LIA!!!!',
    :content => 'LIA sökes blablabla...'
}
```

Inloggningsuppgifter får skriptet själv lösa.

# Exempel

`generation_expression.rb`:
```ruby
require 'uri'
require 'net/http'

uri = URI('http://localhost:11434/api/generate')

Net::HTTP.start(uri.host, uri.port) do |http|
  res = JSON.parse(http.post(uri, {
    'model': 'llama3.1:8b',
    'stream': false,
    'options': { 'top_p': 1 },
    'prompt': """
    Här kommer mycket information om ett företag som heter #{data[:company]}.
    Du ska skriva ett par meningar till en arbetsgivare hos det här företaget.
    Skriv det som att du ska söka praktik där.
    Hälsa inte, och introducera inte dig själv. Var abstrakt och varm.
    Förklara inte till dem vad de gör. Säg istället hur du känner, och vad du gillar.
    I stället för att säga \"ert företag\", säg företagets namn.

    #{data[:company_info]}
    """
  }.to_json).body)['response']

  {
    :subject => 'LIA-praktik sökes 8/9-28/11',
    :content => """
Hej #{data[:name]},

Jag heter Bob Bobsson och går på IT-Högskolan i Stockholm.
Jag söker inte någon specifik tjänst hos #{data[:company]}, men jag undrar om ni har i intresse att ta emot en LIA-student som jag.
Från den 8 september t.o.m. 28 november har jag min första LIA-praktik.
#{res}
Bifogat är ett personligt brev, mitt CV och information från min skola.
Om ni känner att en LIA hos er är möjlig, tar jag gärna vidare kontakt med er!
Tack så mycket!

Vänligen,
Bob Bobsson"""
  }
end
```

[Aktivera SMTP i Gmail!](https://mailtrap.io/blog/gmail-smtp/)

`mail_send.rb`:
```ruby
require 'mail'

Mail.defaults do
  delivery_method :smtp, {
    :address => 'smtp.google.com',
    :port => 587,
    :user_name => ENV['SMTP_USER_NAME'],
    :password => ENV['SMTP_PASSWORD'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
end

Mail.deliver do
  from ENV['SMTP_USER_NAME']
  to data[:email]
  subject data[:subject]
  body data[:content]
  Dir['mail_attachments/*'].each { |a| add_file a }
end
```

Skapa en mapp vid namn `mail_attachments`, och lägg in alla filer som ska skickas med i mejlet. De kommer att skickas med samma filnamn.

Utför till sist programmet i bash:
```bash
DATA="$(cat employer_data.json)" ENTRIES='entries.csv' GENERATION_EXPRESSION="$(cat generation_expression.rb)" MAIL_SEND="$(cat mail_send.rb)" SMTP_USER_NAME='my_mail@gmail.com' SMTP_PASSWORD='my_smtp_p4s5w0rd' ./main.rb
```
Byt ut `SMTP_USER_NAME` och `SMTP_PASSWORD` med dina SMTP-inloggningsuppgifter.
