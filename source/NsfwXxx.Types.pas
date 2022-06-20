//♡2022 by Kisspeace. https://github.com/kisspeace
unit NsfwXxx.Types;

interface
uses
  Sysutils, System.Generics.Collections;

type

  TNsfwItemType = (Image, Video, Gallery);
  TNsfwItemTypes = set of TNsfwItemType;

  TNsfwOri = (Straight, Bizarre, Cartoons, Gay, Shemale);
  TNsfwOris = Set of TNsfwOri;

  TNsfwSort = (Recommended, Newest, Popular);
  TNsfwUrlType = (Default, User, Category, Related);
  TNsfwTagType = (RedditTag, SourceTag, CategoryTag);

  TNsfwXxxUser = record
    Name: string;
    ImageCount: integer;
    VideoCount: integer;
    AvatarUrl: string;
    class function New: TNsfwXxxUser; static;
    constructor Create(AName: string);
  end;

  TNsfwXxxItem = record
    Id: int64;
    Likes: integer;
    Dislikes: integer;
    Comments: integer;
    Username: string;
    UserAvatarUrl: string;
    Thumbnails: TArray<string>;
    Passed: string;
    Caption: string;
    Categories: TArray<string>;
    PostUrl: string;
    ItemType: TNsfwItemType;
    function GetThumb: string;
    class function New: TNsfwXxxItem; static;
    constructor Create(AId: int64);
  end;

  TNsfwXxxItemAr = TArray<TNsfwXxxItem>;
  TNsfwXxxItemList = Tlist<TNsfwXxxItem>;

  TNsfwXxxPostPage = record
    Poster: string;
    Items: TNsfwXxxItemAr; // Items[0] is current post
    function GetContentUrl: String;
    class function New: TNsfwXxxPostPage; static;
    constructor Create(AId: int64);
  end;



implementation

{ TNsfwXxxItem }

function TNsfwXxxItem.GetThumb: string;
begin
  if Length(Thumbnails) > 0 then
    Result := Thumbnails[0];
end;

class function TNsfwXxxItem.New: TNsfwXxxItem;
begin
  Result := TNsfwXxxItem.Create(0);
end;

constructor TNsfwXxxItem.Create(AId: int64);
begin
  Id            := Aid;
  Likes         := 0;
  Dislikes      := 0;
  Comments      := 0;
  Username      := '';
  UserAvatarUrl := '';
  Thumbnails    := [];
  Passed        := '';
  Caption       := '';
  Categories    := [];
  PostUrl       := '';
  ItemType      := TNsfwItemType.Image;
end;

{ TNsfwXxxUser }

constructor TNsfwXxxUser.Create(AName: string);
begin
  Name       := AName;
  ImageCount := 0;
  VideoCount := 0;
  AvatarUrl  := '';
end;

class function TNsfwXxxUser.New: TNsfwXxxUser;
begin
  Result := TNsfwXxxUser.Create('');
end;

{ TNsfwXxxPage }

constructor TNsfwXxxPostPage.Create(AId: int64);
begin
  items   := [];
  Poster  := '';
end;

function TNsfwXxxPostPage.GetContentUrl: String;
begin
  Result := '';
  if ( (Length(Items) > 0) And (length(Items[0].Thumbnails) > 0) ) then begin
      Result := Items[0].Thumbnails[0]
  end;
end;

class function TNsfwXxxPostPage.New: TNsfwXxxPostPage;
begin
  Result := TNsfwXxxPostPage.Create(0);
end;

end.
