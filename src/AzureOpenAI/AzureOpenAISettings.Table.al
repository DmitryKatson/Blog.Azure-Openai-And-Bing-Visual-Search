table 60101 "GPT Azure OpenAI Settings"
{
    Caption = 'AzureAI Settings';
    DataPerCompany = false;
    ReplicateData = false;
    Extensible = false;
    Access = Internal;

    fields
    {
        field(1; Id; Code[10])
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }

        field(2; Endpoint; Text[250])
        {
            Caption = 'Endpoint';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Uri: Codeunit Uri;
            begin
                ClearSecret();

                Rec.Endpoint := CopyStr(Rec.Endpoint.Trim(), 1, MaxStrLen(Rec.Endpoint));

                if Rec.Endpoint = '' then begin
                    Rec.Endpoint := '';
                    exit;
                end;

                if not Uri.IsValidUri(Rec.Endpoint) then
                    Error(UriNotValidErr);

                Uri.Init(Rec.Endpoint);
                if Uri.GetScheme().ToLower() <> 'https' then
                    Error(UriNotHttpsErr);
            end;
        }

    }
    keys
    {
        key(Key1; Id)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ClearSecret();
    end;

    [NonDebuggable]
    procedure SetSecret(Secret: Text)
    begin
        IsolatedStorage.Set(SecretKeyTok, Secret, DataScope::Module);
    end;

    procedure ClearSecret()
    begin
        if IsolatedStorage.Delete(SecretKeyTok, DataScope::Module) then;
    end;

    procedure HasSecret(): Boolean
    begin
        exit(IsolatedStorage.Contains(SecretKeyTok, DataScope::Module));
    end;

    [NonDebuggable]
    procedure GetSecret() APIKey: Text
    begin
        IsolatedStorage.Get(SecretKeyTok, DataScope::Module, APIKey);
    end;

    procedure GetEndpoint(): Text
    var
        MissingEndpointErrorInfo: ErrorInfo;
    begin
        Rec.Get();

        if Rec.Endpoint = '' then begin
            MissingEndpointErrorInfo.Title := 'Ouch!';
            MissingEndpointErrorInfo.Message := 'Endpoint must be specified in Azure OpenAI Settings';
            MissingEndpointErrorInfo.PageNo(Page::"GPT Azure OpenAI Settings");
            MissingEndpointErrorInfo.AddNavigationAction('Configure Azure OpenAI');
            Error(MissingEndpointErrorInfo);
        end;

        exit(Rec.Endpoint);
    end;

    var
        SecretKeyTok: Label 'GPT-AOAI-Key', Locked = true;
        UriNotValidErr: Label 'The specified endpoint is not valid.';
        UriNotHttpsErr: Label 'The specified endpoint should be using https.';
}