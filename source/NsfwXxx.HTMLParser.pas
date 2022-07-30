//♡2022 by Kisspeace. https://github.com/kisspeace
unit NsfwXxx.HTMLParser;

interface

uses
  NsfwXxx.Types, classes, sysutils,
  //System.NetEncoding,
  {*HTMLp*}
  HTMLp.Entities,
  HTMLp.DOMCore,
  HTMLp.HtmlTags,
  HTMLp.HtmlReader,
  HTMLp.HtmlParser,
  HTMLp.Formatter;

type
  TProcParsePostHasPoster = reference to procedure (AId: int64; APoster: string);

  //function TranslateUrlToTag(Aurl: string): string;
  function GetTagType(var AReqParam: string): TNsfwTagType;

  function ParsePostsFromNodes(ANodes: TNodeList; AProcHasPoster: TProcParsePostHasPoster = nil): TNsfwXxxItemAr;
  function ParsePosts(const AContent: string): TNsfwXxxItemAr;
  function ParsePostPage(const AContent: string): TNsfwXxxPostPage;

  function CreateUrl(AMode: TNsfwUrlType; AParam: string; APageNum: integer;
    Asort: TnsfwSort; ATypes: TNsfwItemTypes; AOrientations: TNsfwOris;
    AHost: string): string;

implementation

function GetTagType(var AReqParam: string): TNsfwTagType;
begin
  if ( Pos('/R/', uppercase(AReqParam)) > 0 ) then
    Result := TNsfwTagType.RedditTag    //Reddit
  else if ( Pos('.', AReqParam) > 0 ) then
    Result := TNsfwTagType.SourceTag    //Source
  else
    Result := TNsfwTagType.CategoryTag; //Category
end;

function ParsePostPage(const AContent: string): TNsfwXxxPostPage;
var
  Parser: THTMLParser;
  Doc: TDocument;
  Nodes: TNodeList;
  LPoster: string;
begin
  Result := TNsfwXxxPostPage.New;
  Doc := nil;
  Nodes := nil;
  Parser := THTMLParser.Create;
  LPoster := '';
  try
    Doc := Parser.ParseString(AContent);
    Nodes := Doc.DocumentElement.GetElementsByClass('sh-section', true);
    Result.items := ParsePostsFromNodes(Nodes,
      procedure (Aid: int64; APoster: string)
      begin
        LPoster := APoster;
      end
    );
    Result.Poster := LPoster;

  finally
    FreeandNil(Doc);
    Parser.Free;
  end;
end;

function ParsePostsFromNodes(ANodes: TNodeList;
 AProcHasPoster: TProcParsePostHasPoster = nil): TNsfwXxxItemAr;
var
  Nodes, Tmps: TNodeList;
  N, NTmp: TNode;
  E, Tmp: TElement;
  I, X: integer;
  Item: TNsfwXxxItem;
  Str: string;

  procedure SetValue(var AVar: string; ANode: TNode); overload;
  begin
    if assigned(ANode) then
      AVar := ANode.Value;
  end;

  procedure SetValue(var AVar: integer; ANode: TNode); overload;
  begin
    if assigned(ANode) then
      TryStrToInt(ANode.Value, AVar);
  end;

  function GetSrcAttr(ANode: TNode): string;
  var
    A: TNode;
  begin
    A := ANode.Attributes.GetNamedItem('src');
    if not Assigned(A) then
      A := ANode.Attributes.GetNamedItem('data-src');
    if Assigned(A) then
      Result := A.Value
    else
      Result := '';
  end;

begin
  Result := [];
  for I := 0 to ANodes.Count - 1 do begin
    N := ANodes.Items[I];
    try
      E := (N as TElement);
    except
      Continue;
    end;

    var Section: TElement := E.GetElementByClass('sh-section__head');
    if Assigned(Section) then begin
      Item := TNsfwXxxItem.New;

      //Passed
      SetValue(Item.Passed, Section.GetElementByClass('sh-section__passed'));

      //User avatar and name
      var UserAva: TElement := Section.GetElementByClass('lazyload');
      if Assigned(UserAva) then begin
        Item.UserAvatarUrl := UserAva.GetAttribute('data-src');
        Item.Username      := UserAva.GetAttribute('alt');
      end;

      //Thumbnail and caption
      var Content: TElement := E.GetElementByClass('sh-section__content');
      if Assigned(Content) then begin

        //Caption
        SetValue(Item.Caption, Content.GetElementByTagName('p')); // nsfw.xxx only
        //Item.Caption := THTMLEncoding.HTML.Decode(Item.Caption);

        //PostUrl
        Tmp := Content.GetElementByClass('slider_init_href', true);
        if Assigned(tmp) then
          Item.PostUrl := Tmp.GetAttribute('href');


        //Itemtype
        if Assigned(Content.GetElementByClass('sh-section__media')) then
          Item.ItemType := TNsfwItemType.Video;

        Tmp := Content.getElementByTagName('video');
        if ( Assigned(Tmp) And Assigned(AProcHasPoster) ) then
          AProcHasPoster(Item.Id, Tmp.GetAttribute('poster'));

        //Thumbnails
        Tmps := Content.GetElementsByTagName('img', Integer.MaxValue);
        if ( Tmps.Count < 1 ) then begin
          Tmps := Content.GetElementsByTagName('source', Integer.MaxValue);
          Item.ItemType := TNsfwItemType.Video;
        end else begin
          if Length(Item.Thumbnails) > 1 then
            Item.ItemType := TNsfwItemType.Gallery;
        end;

        // Parse Captions for ( pornpic.xxx, hdporn.pics )
        if ( Tmps.Count > 0 ) and ( Item.Caption.IsEmpty ) then begin
          var LNode: TNode;
          LNode := Tmps.GetFirst.Attributes.GetNamedItem('alt');
          if Assigned(LNode) then
            Item.Caption := LNode.Value;
        end;

        for X := 0 to Tmps.Count - 1 do begin
          Str := GetSrcAttr(Tmps.Items[X]);
          if not Str.IsEmpty then
            Item.Thumbnails := Item.Thumbnails + [Str];
        end;

      end;

      //Categories / likes (And dislikes) / comments count
      var Footer: TElement := E.GetElementByClass('sh-section__footer');
      if Assigned(Footer) then begin

        //Categories
        Tmp := Footer.GetElementByClass('sh-section__footer-categories');
        if Assigned(Tmp) then begin
          Tmps := Tmp.GetElementsByTagName('span', Integer.MaxValue);
          for X := 0 to Tmps.Count - 1 do begin
            Item.Categories := Item.Categories + [Tmps.Items[X].Value];
          end;
        end;

        //Counts
        Tmp := Footer.GetElementByClass('sh-section__btns-right');
        if Assigned(Tmp) then begin

          var Likes: TElement := Tmp.GetElementByClass('sh-section__btn-like');
          if Assigned(Likes) then begin
            //Post id
            if TryStrToInt64(Likes.GetAttribute('data-post-id'), Item.Id) then begin
              //Likes
              SetValue(Item.Likes, Likes.GetElementByID('like-value-id-' + Item.Id.ToString));
              //Dislikes
              SetValue(Item.Dislikes, Tmp.GetElementByID('dislike-value-id-' + Item.Id.ToString));
              //Post Url
//              Tmp := Tmp.GetElementByClass('js-report-button');
//              if Assigned(Tmp) then
//                Item.PostUrl := Tmp.GetAttribute('data-url');
            end;
          end;

          //Comments
          var Btn: TElement := Tmp.GetElementByClass('sh-section__btn-comment');
          if Assigned(Btn) then begin
            SetValue(Item.Comments, Btn.GetElementByTagName('span'));
          end;

        end;

      end;

      Result := Result +[Item];
    end;
  end;
end;

function ParsePosts(const AContent: string): TNsfwXxxItemAr;
var
  Parser: THTMLParser;
  Doc: TDocument;
  E, Tmp: TElement;
begin
  Doc := nil;
  Result := [];
  Parser := THTMLParser.Create;
  try
    Doc := Parser.ParseString(Acontent);
    E := Doc.DocumentElement.GetElementByTagName('body');
    //writeln(E.GetInnerHTML);
    Result := ParsePostsFromNodes(E.ChildElements);
  finally
    FreeandNil(Doc);
    Parser.Free;
  end;
end;

function CreateUrl(AMode: TNsfwUrlType; AParam: string; APageNum: integer;
  Asort: TnsfwSort; ATypes: TNsfwItemTypes; AOrientations: TNsfwOris;
  AHost: string): string;
var
  i: integer;
  LOrientations: string;
  LContentTypes: string;
  First, Last: string;
  TagType: TnsfwtagType;
begin

  //Orientations
  if not ( AOrientations = [] ) then begin
    for i :=0 to 4 do begin
      if TNsfwOri(i) in AOrientations then begin
        LOrientations := LOrientations + 'nsfw[]=' + inttostr(i) + '&';
      end;
    end;
  end;

  //Content types
  if not ( ATypes = [] ) then begin
    if Image in Atypes then
      LContentTypes := LContentTypes + 'types[]=image&';
    if Video in Atypes then
      LContentTypes := LContentTypes + 'types[]=video&';
    if Gallery in Atypes then
      LContentTypes := LContentTypes + 'types[]=gallery&';
  end;

  if ( AMode = Default ) then begin
    //if SearchBy string req
    if not Aparam.IsEmpty then last := 'q=' + Aparam;

    if ( Asort = Recommended ) then begin
      //recommended
      if Aparam.IsEmpty then begin
        first := AHost + '/index-page/' + inttostr(Apagenum);
      end else
        first := AHost + '/search-page/' + inttostr(Apagenum);
    end else if (Asort = popular) then begin
      //popular
      if Aparam.IsEmpty then begin
        first := AHost + '/page/' + inttostr(Apagenum) + '/popular';
      end else begin
        first := AHost + '/search-page/' + inttostr(Apagenum);
        last := last + '&sort=popular'
      end;

    end else begin
      //mewest
      if Aparam.IsEmpty then begin
        first := AHost + '/search-page/' + inttostr(Apagenum) + '/newest';
      end else begin
        first := AHost + '/search-page/' + inttostr(Apagenum);
        last := last + '&sort=newest'
      end;
    end;


  end else if ( AMode = user ) then begin
    //if search by user
    last := 'user=' + Aparam;

    if ( Asort = newest ) then begin
      first := AHost + '/page/' + inttostr(Apagenum) + '/newest';
    end else begin
      first := AHost + '/page/' + inttostr(Apagenum);
    end;

  end else begin
    //if search by category
    TagType := GetTagType(AParam);

    if ( TagType = CategoryTag ) then begin
      AParam := AParam.Replace('/', '-', [rfReplaceAll]);
      AParam := AParam.Replace(' ', '-', [rfReplaceAll]);
    end;

    case TagType of
      RedditTag:   last := 'source=' + Aparam;
      SourceTag:   last := 'provider=' + Aparam;
      CategoryTag: last := 'category=' + Aparam;
    end;

    case ASort of
      Recommended: begin
        if (TagType <> CategoryTag)  then
          first := AHost + '/page/' + inttostr(Apagenum)
        else
          first := AHost + '/category-page/' + Aparam + '/' + inttostr(Apagenum);
      end;

      Newest: begin
        if (TagType <> CategoryTag) then
          first := AHost + '/page/' + inttostr(Apagenum) + '/newest'
        else
          first := AHost + '/category-page/' + Aparam + '/' +
           inttostr(Apagenum) + '/newest';
      end;

      Popular: begin
        if (TagType <> CategoryTag) then
          first := AHost + '/page/' + inttostr(Apagenum)
        else
          first := AHost + '/category-page/' + Aparam + '/' +
           inttostr(Apagenum) + '/popular';
      end;
    end;
  end;

  Result := first + '?' + LOrientations + LContentTypes +
    'slider=0&jsload=1&' + last;
end;

end.
