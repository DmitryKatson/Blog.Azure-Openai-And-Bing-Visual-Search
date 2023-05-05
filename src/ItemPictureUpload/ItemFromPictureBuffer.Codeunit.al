codeunit 60103 "GPT Item From Picture Buffer"
{
    SingleInstance = true;

    var
        ItemTemp: Record Item temporary;

    procedure SaveItemToBuffer(Item: Record Item);
    begin
        ItemTemp := Item;
    end;

    procedure GetItemFromBuffer(var Item: Record Item);
    begin
        Item := ItemTemp;
    end;

    procedure ClearItemFromBuffer()
    begin
        Clear(ItemTemp);
    end;
}