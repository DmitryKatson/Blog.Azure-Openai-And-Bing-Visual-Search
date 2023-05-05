page 60101 "GPT Azure OpenAI Settings"
{
    ApplicationArea = All;
    Caption = 'Azure OpenAI Settings';
    AdditionalSearchTerms = 'AI,GPT,OpenAI';
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "GPT Azure OpenAI Settings";
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
                    ToolTip = 'Specifies the endpoint to use. You can find endpoint in the ''Azure OpenAI Studio''. Just click ''View Code'' and you will find an endpoint. To construct the endpoint you should follow next logic https://[resourceName].openai.azure.com/openai/deployments/[ModelDeploymentName]/chat/completions?api-version=2023-03-15-preview. If you don''t have Azure OpenAI resource, you can create on https://portal.azure.com';
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