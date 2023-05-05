codeunit 60102 "GPT Item from Picture Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Templ. Mgt.", OnAfterCreateItemFromTemplate, '', false, false)]
    local procedure OnAfterCreateItemFromTemplate(var Item: Record Item; ItemTempl: Record "Item Templ.");
    var
        ItemFromImageBuffer: Codeunit "GPT Item from Picture Buffer";
    begin
        ItemFromImageBuffer.SaveItemToBuffer(Item);
    end;


    [EventSubscriber(ObjectType::Table, Database::"Item", OnAfterModifyEvent, '', false, false)]
    local procedure AIGenerateNameAndRecipe(var Rec: Record Item; var xRec: Record Item)
    var
        ItemFromImageBuffer: Codeunit "GPT Item from Picture Buffer";
        ItemTemp: Record Item temporary;
    begin
        if IsNullGuid(Rec.Picture.MediaId) then
            exit;

        if Rec.Picture.Count = 0 then
            exit;

        ItemFromImageBuffer.GetItemFromBuffer(ItemTemp);
        if IsNullGuid(ItemTemp.SystemId) then
            exit;

        Rec.Description := CopyStr(GenerateNameFromItemPicture(Rec), 1, MaxStrLen(Rec.Description));
        GenerateRecipeFromItemNameAndAddToNotes(Rec);
        ItemFromImageBuffer.ClearItemFromBuffer();
        Rec.Modify();
    end;

    local procedure GenerateNameFromItemPicture(var Item: Record Item): Text
    var
        PicInStream: InStream;
        TenantMedia: Record "Tenant Media";
        BingVisualSearchImpl: codeunit "GPT Bing Visual Search Impl.";
        AzureOpenAIImpl: codeunit "GPT Azure OpenAI Impl.";
    begin
        TenantMedia.Get(Item.Picture.Item(1));
        TenantMedia.Calcfields(Content);
        if not TenantMedia.Content.HasValue then
            exit;

        TenantMedia.Content.CreateInStream(PicInStream);

        exit(AzureOpenAIImpl.GetAIGeneratedItemName(BingVisualSearchImpl.Search(PicInStream)));
    end;

    local procedure GenerateRecipeFromItemNameAndAddToNotes(var Item: Record Item)
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
        AzureOpenAIImpl: codeunit "GPT Azure OpenAI Impl.";

    begin
        RecordLink."Record ID" := Item.RecordId;
        RecordLink.Type := RecordLink.Type::Note;
        RecordLink.Description := 'Recipe';
        RecordLinkManagement.WriteNote(RecordLink, AzureOpenAIImpl.GetAIGeneratedItemRecipe(Item.Description));
        RecordLink.Created := CurrentDateTime;
        RecordLink.Company := CopyStr(CompanyName, 1, MaxStrLen(RecordLink.Company));
        RecordLink.Insert();
    end;

}