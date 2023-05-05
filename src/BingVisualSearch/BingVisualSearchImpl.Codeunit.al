codeunit 60100 "GPT Bing Visual Search Impl."
{
    procedure Search(var PictureInStream: InStream) FoundDescriptions: Text
    var
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        Content: HttpContent;
        Client: HttpClient;
        ResponseText: Text;
        BingSearchSetup: Record "GPT Bing Search Settings";
    begin
        // configure url and request type
        Request.Method('POST');
        Request.SetRequestUri(BingSearchSetup.GetEndpoint());

        // configure headers
        Request.GetHeaders(Headers);
        Headers.Add('Accept', 'application/json');
        Headers.Add('Ocp-Apim-Subscription-Key', BingSearchSetup.GetSecret());

        // configure content
        BuildFormDataContent(PictureInStream, Content);

        Request.Content := Content;

        Client.Send(Request, Response);

        Response.Content.ReadAs(ResponseText);

        FoundDescriptions := BuildDescriptions(ResponseText).ToText();
    end;

    local procedure BuildFormDataContent(var PictureInStream: InStream; var Content: HttpContent)
    var
        ContentHeaders: HttpHeaders;
        TempBlob: Codeunit "Temp Blob";
        PayloadInStream: InStream;
        PayloadOutStream: OutStream;
        CR: Char;
        LF: Char;
        NewLine: Text;
    begin
        CR := 13;
        LF := 10;
        NewLine += '' + CR + LF;

        Content.GetHeaders(ContentHeaders);
        ContentHeaders.Clear();
        ContentHeaders.Add('Content-Type', 'multipart/form-data; boundary=boundary');

        TempBlob.CreateOutStream(PayloadOutStream);
        PayloadOutStream.WriteText('--boundary' + NewLine);
        PayloadOutStream.WriteText('Content-Disposition: form-data; name="image"; fileName="image.jpeg"' + NewLine);
        PayloadOutStream.WriteText('Content-Type: application/octet-stream' + NewLine);
        PayloadOutStream.WriteText(NewLine);
        // Copy all bytes from the uploaded file to the stream
        CopyStream(PayloadOutStream, PictureInStream);
        PayloadOutStream.WriteText(NewLine);
        PayloadOutStream.WriteText('--boundary--' + NewLine);

        // Copy all bytes from the write stream to a read stream.
        TempBlob.CreateInStream(PayloadInStream);
        // Write all bytes from the request body stream.
        Content.WriteFrom(PayloadInStream);
    end;

    local procedure BuildDescriptions(var ResponseText: Text) ImageDescriptions: TextBuilder
    var
        BingVisionResponseJObj: JsonObject;
        Jtok: JsonToken;
        SearchResults: JsonArray;
        NameJTok: JsonToken;
        i: Integer;
    begin
        BingVisionResponseJObj.ReadFrom(ResponseText);

        BingVisionResponseJObj.SelectToken('tags[0].actions[0].data.value', Jtok);
        SearchResults := Jtok.AsArray();

        for i := 0 to GetMaxNumberOfResults(SearchResults) do begin
            SearchResults.Get(i, Jtok);
            Jtok.SelectToken('name', NameJTok);
            ImageDescriptions.Append(NameJTok.AsValue().AsText());
        end;
    end;

    local procedure GetMaxNumberOfResults(var SearchResults: JsonArray): Integer
    begin
        if SearchResults.Count > 5 then
            exit(5)
        else
            exit(SearchResults.Count - 1);
    end;
}