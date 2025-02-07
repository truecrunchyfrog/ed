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
