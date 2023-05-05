codeunit 60101 "GPT Azure OpenAI Impl."
{
    procedure GetAIGeneratedItemName(InputText: Text) Name: Text
    var
        Prompt: Text;
        Completion: Text;
    begin
        Prompt := 'You are a ChiefGPT. You will be provided by food descriptions of the same food, separated by ''|''. ' +
                'You should analyse descriptions and tell me the name of the food. ' +
                'IMPORTANT! Don''t add additional comment like ''the food is'', return just food name.' +
                'Example: ' +
                'Description: ''The food is a fruit. It is red. It is round. It is sweet'' ' +
                'Answer: ''apple'' ' +
                'Description: ' +
                '_______';

        Completion := GenerateCompletion(Prompt, InputText);

        exit(Completion);
    end;

    procedure GetAIGeneratedItemRecipe(InputText: Text) Recipe: Text
    var
        Prompt: Text;
        Completion: Text;
    begin
        Prompt := 'You are a ChiefGPT. You will be provided by food name. ' +
                'You should return me a food recipe. ' +
                'Don''t add additional comment like ''the recipe is'', return just recipe. ' +
                'Food Name: ' +
                '_______';

        Completion := GenerateCompletion(Prompt, InputText);

        exit(Completion);
    end;


    internal procedure GenerateCompletion(Prompt: Text; InputText: Text): Text;
    var
        Configuration: JsonObject;
        Completion: Text;
        NewLineChar: Char;
    begin
        Configuration.Add('max_tokens', 800);
        Configuration.Add('temperature', 0);
        Configuration.Add('messages', GetMessages(Prompt, InputText));

        Completion := SendCompletionRequest(Configuration);

        NewLineChar := 10;
        if StrLen(Completion) > 1 then
            Completion := CopyStr(Completion, 2, StrLen(Completion) - 2);
        Completion := Completion.Replace('\n', NewLineChar);
        Completion := DelChr(Completion, '<>', ' ');
        Completion := Completion.Replace('\"', '"');
        Completion := Completion.Trim();

        exit(Completion);
    end;

    internal procedure GetMessages(Prompt: Text; InputText: Text): JsonArray;
    var
        Messages: JsonArray;
        Message: JsonObject;
    begin
        Clear(Message);
        Message.Add('role', 'system');
        Message.Add('content', Prompt);
        Messages.Add(Message);

        Clear(Message);
        Message.Add('role', 'user');
        Message.Add('content', InputText);
        Messages.Add(Message);

        exit(Messages);
    end;

    internal procedure SendCompletionRequest(Configuration: JsonObject): Text;
    var
        AzureOpenAISettings: record "GPT Azure OpenAI Settings";

        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        Client: HttpClient;
        StatusCode: Integer;

        Payload: Text;
        ResponseText: Text;
        ResponseJson: JsonObject;
        CompletionToken: JsonToken;
        Completion: Text;
    begin
        Configuration.WriteTo(Payload);

        Request.Method('POST');
        Request.SetRequestUri(AzureOpenAISettings.GetEndpoint());

        Client.DefaultRequestHeaders().Add('api-key', AzureOpenAISettings.GetSecret());
        Content.WriteFrom(Payload);

        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        Request.Content(Content);
        Client.Send(Request, Response);

        StatusCode := Response.HttpStatusCode();
        if not Response.IsSuccessStatusCode() then
            Error(CompletionFailedErr, Response.HttpStatusCode, Response.ReasonPhrase);

        Response.Content().ReadAs(ResponseText);

        ResponseJson.ReadFrom(ResponseText);
        ResponseJson.SelectToken('$.choices[:].message.content', CompletionToken);
        CompletionToken.WriteTo(Completion);

        exit(Completion);
    end;

    var
        CompletionFailedErr: Label 'The completion did not return a success status code. Status code: %1.\Reason: %2', Comment = '%1 is the http status code of the failed request (e.g. 401)\%2 is the reason phrase of the failed request (e.g. Unauthorized)';
}