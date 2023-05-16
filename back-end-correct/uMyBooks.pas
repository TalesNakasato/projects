unit uMyBooks;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef, FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, Data.DB, Vcl.Grids, Vcl.DBGrids,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Horse, Horse.Cors, System.JSON;

type
  TForm1 = class(TForm)
    FDConnection1: TFDConnection;
    FDQuery1: TFDQuery;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

  private
    procedure registerBook(req: THorseRequest; Res: THorseResponse);
    procedure getBooks(req: THorseRequest; Res: THorseResponse);
    procedure getSelectedBook(req: THorseRequest; Res: THorseResponse);
    procedure removeBook(req: THorseRequest; Res: THorseResponse);
    procedure editBook(req: THorseRequest; Res: THorseResponse);

  public
    procedure registry;

  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.registry;
begin
     THorse.Post('/registerBook', registerBook);
     THorse.Get('/myBooks', getBooks);
     THorse.Post('/selectedBook', getSelectedBook);
     THorse.Delete('/removeBooks', removeBook);
     THorse.Put('/editBooks', editBook);
end;

procedure TForm1.removeBook(req: THorseRequest; Res: THorseResponse);
var
     xQuery : TFDQuery; // DB
     xbookId : String;
     jsonRequest : TJSONValue;
begin
     try
        if req.Body.IsEmpty then
        begin
             res.Send('erro').Status(THTTPStatus.BadRequest);
             exit
        end;

        jsonRequest := TJSONObject.ParseJSONValue(req.Body);

        // Book's fields
        xbookId := EmptyStr;
        jsonRequest.TryGetValue('id', xbookId);

        try
          xQuery := TFDQuery.Create(nil);
          xQuery.Connection := FDConnection1;
          xQuery.SQL.Text := 'DELETE from myBooks where id = :id';

          xQuery.ParamByName('id').AsString := xbookId;

          xQuery.Execute;

          // use xQuery.Execute for post, put and delete, and xQuery.Open para get/select
          res.Send('Book removed!').Status(THTTPStatus.OK);

        except on E: Exception do
           res.Send(E.Message).Status(THTTPStatus.BadRequest);
        end;

     finally
        FreeAndNil(xQuery);
     end;
end;

procedure TForm1.registerBook(req: THorseRequest; Res: THorseResponse);
var
     xQuery : TFDQuery; // DB
     xbookName, xauthor, xpublisher, xobservation : String;
     jsonRequest : TJSONValue;
begin
     try
        if req.Body.IsEmpty then
        begin
             res.Send('erro').Status(THTTPStatus.BadRequest);
             exit
        end;

        jsonRequest := TJSONObject.ParseJSONValue(req.Body);

        // Book's fields
        xbookName := EmptyStr;
        jsonRequest.TryGetValue('bookName', xbookName);
        xauthor := EmptyStr;
        jsonRequest.TryGetValue('author', xauthor);
        xpublisher := EmptyStr;
        jsonRequest.TryGetValue('publisher', xpublisher);
        xobservation := EmptyStr;
        jsonRequest.TryGetValue('observation', xobservation);

        try
          xQuery := TFDQuery.Create(nil);
          xQuery.Connection := FDConnection1;
          xQuery.SQL.Text := 'INSERT myBooks (bookName, author, publisher, observation)' +
                            'VALUES (:bookName, :author, :publisher, :observation)';

          xQuery.ParamByName('bookName').AsString := xbookName;
          xQuery.ParamByName('author').AsString := xauthor;
          xQuery.ParamByName('publisher').AsString := xpublisher;
          xQuery.ParamByName('observation').AsString := xobservation;

          xQuery.Execute;
          // use xQuery.Execute for post, put and delete, and xQuery.Open para get/select

          res.Send('Book registered succesfuly').Status(THTTPStatus.OK);

        except on E: Exception do
           res.Send(E.Message).Status(THTTPStatus.BadRequest);
        end;

     finally
        FreeAndNil(xQuery);
     end;
end;

procedure TForm1.getBooks(req: THorseRequest; Res: THorseResponse);
var
     xQuery : TFDQuery; // DB
//     xbookName, xauthor, xpublisher, xobservation : String;
//     jsonRequest : TJSONValue;
     JsonSend : TJSONObject;
     JsonArraySend : TJSONArray;
begin
     try
        try
          xQuery := TFDQuery.Create(nil);
          xQuery.Connection := FDConnection1;
          xQuery.SQL.Text := 'SELECT * FROM myBooks';

          xQuery.Open;

          xQuery.First;

          JsonArraySend := TJSONArray.Create();

          while not (xQuery.eof) do
          begin
              JsonSend := TJSONObject.Create();
              JsonSend.AddPair('message','Requisition Success');
              JsonSend.AddPair('id',XQuery.fieldbyname('id').AsString);
              JsonSend.AddPair('bookName',xQuery.fieldbyname('bookName').AsString);
              JsonSend.AddPair('author',xQuery.fieldbyname('author').AsString);
              JsonSend.AddPair('publisher',xQuery.fieldbyname('publisher').AsString);
              JsonSend.AddPair('observation',xQuery.fieldbyname('observation').AsString);
              JsonArraySend.AddElement(JsonSend);
              xQuery.Next;
          end;

          res.Send(JsonArraySend.ToJSON).ContentType('application/json').Status(THTTPStatus.OK);

        except on E: Exception do
           res.Send(E.Message).Status(THTTPStatus.BadRequest);
        end;

     finally
        FreeAndNil(xQuery);
     end;
end;

procedure TForm1.getSelectedBook(req: THorseRequest; Res: THorseResponse);
var
     xQuery : TFDQuery; // DB
     xbookId : String;
     jsonRequest : TJSONValue;
     JsonSend : TJSONObject;
begin
     try
        if req.Body.IsEmpty then
        begin
             res.send('Empty Body').Status(THTTPStatus.BadRequest);
             exit;
        end;

        jsonRequest := TJSONObject.ParseJSONValue(req.Body);

        xbookId :=  EmptyStr;

        jsonRequest.TryGetValue('id',xbookId);

        if xbookId.IsEmpty then
        begin
           res.send('unfilled id ').Status(THTTPStatus.BadRequest);
           exit;
        end;

        try

          xQuery := TFDQuery.Create(nil);
          xQuery.Connection := FDConnection1;
          xQuery.SQL.Text := 'SELECT * FROM myBooks where id = :id';

          xQuery.ParamByName('id').AsString := xbookId;

          xQuery.Open;

          JsonSend := TJSONObject.Create();

          JsonSend.AddPair('message','Requisition Success');
          JsonSend.AddPair('id',XQuery.fieldbyname('id').AsString);
          JsonSend.AddPair('bookName',xQuery.fieldbyname('bookName').AsString);
          JsonSend.AddPair('author',xQuery.fieldbyname('author').AsString);
          JsonSend.AddPair('publisher',xQuery.fieldbyname('publisher').AsString);
          JsonSend.AddPair('observation',xQuery.fieldbyname('observation').AsString);

          res.Send(JsonSend.ToJSON).ContentType('application/json').Status(THTTPStatus.OK);

        except on E: Exception do
           res.Send(E.Message).Status(THTTPStatus.BadRequest);
        end;

     finally
        FreeAndNil(xQuery);
     end;
end;

procedure TForm1.editBook(req: THorseRequest; Res: THorseResponse);
var
     xQuery : TFDQuery; // DB
     xbookId, xbookName, xauthor, xpublisher, xobservation  : String;
     jsonRequest : TJSONValue;
begin
     try
        if req.Body.IsEmpty then
        begin
             res.send('Empty Body').Status(THTTPStatus.BadRequest);
             exit;
        end;

        jsonRequest := TJSONObject.ParseJSONValue(req.Body);

        xbookId :=  EmptyStr;
        jsonRequest.TryGetValue('id',xbookId);
        xbookName :=  EmptyStr;
        jsonRequest.TryGetValue('bookName',xbookName);
        xauthor :=  EmptyStr;
        jsonRequest.TryGetValue('author',xauthor);
        xpublisher :=  EmptyStr;
        jsonRequest.TryGetValue('publisher',xpublisher);
        xobservation :=  EmptyStr;
        jsonRequest.TryGetValue('observation',xobservation);

        if xbookId.IsEmpty then
        begin
           res.send('unfilled id').Status(THTTPStatus.BadRequest);
           exit;
        end;

        try

          xQuery := TFDQuery.Create(nil);
          xQuery.Connection := FDConnection1;
          xQuery.SQL.Text := 'update myBooks set bookName = :bookName, author = :author,' +
            'publisher = :publisher, observation = :observation where id = :id;';

          xQuery.ParamByName('id').AsString := xbookId;
          xQuery.ParamByName('bookName').AsString := xbookName;
          xQuery.ParamByName('author').AsString := xauthor;
          xQuery.ParamByName('publisher').AsString := xpublisher;
          xQuery.ParamByName('observation').AsString := xobservation;

          xQuery.Execute;

          res.Send('Succesfuly edited').Status(THTTPStatus.OK);

        except on E: Exception do
           res.Send(E.Message).Status(THTTPStatus.BadRequest);
        end;

     finally
        FreeAndNil(xQuery);
     end;
end;


procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     FDConnection1.Connected := false;
     FDQuery1.Active := false;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
     FDConnection1.Connected := true;
     FDQuery1.Active := true;

     registry;
     THorse.Use(Cors);
     THorse.Listen(9000);
end;
end.
