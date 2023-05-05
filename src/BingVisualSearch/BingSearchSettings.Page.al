page 60100 "GPT Bing Search Settings"
{
    ApplicationArea = All;
    Caption = 'Bing Search Settings';
    AdditionalSearchTerms = 'Bing,Search,VisualSearch';
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "GPT Bing Search Settings";
    UsageCategory = Administration;

    ContextSensitiveHelpPage = 'Food-Picture-2-Recipe--Azure-OpenAI---Bing-Visual-Search-for-Business-Central';

    layout
    {
        area(content)
        {
            group(settings)
            {
                ShowCaption = false;

                field(Endpoint; Rec.Endpoint)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the endpoint to use for the Bing Search API.';
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }

                field(Secret; Secret)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the secret to connect to the endpoint.';
                    Caption = 'Secret';
                    ExtendedDatatype = Masked;

                    trigger OnValidate()
                    begin
                        Rec.SetSecret(Secret);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then
            Rec.Insert();

        Rec.SetDefaults();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec.HasSecret() then
            Secret := SecretPlaceholderLbl
        else
            Clear(Secret);
    end;

    var
        Secret: Text;
        SecretPlaceholderLbl: Label '***', Locked = true;
}