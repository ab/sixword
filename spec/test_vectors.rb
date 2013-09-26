# test vectors
module Sixword
  module TestVectors
    # from RFC 2289 and RFC 1751
    HexTests = {
      'rfc2289 parity' => {
        '85c43ee03857765b' => 'FOWL KID MASH DEAD DUAL OAF',
      },
      'rfc2289 md4' => {
        'D185 4218 EBBB 0B51' => 'ROME MUG FRED SCAN LIVE LACE',
        '6347 3EF0 1CD0 B444' => 'CARD SAD MINI RYE COL KIN',
        'C5E6 1277 6E6C 237A' => 'NOTE OUT IBIS SINK NAVE MODE',
        '5007 6F47 EB1A DE4E' => 'AWAY SEN ROOK SALT LICE MAP',
        '65D2 0D19 49B5 F7AB' => 'CHEW GRIM WU HANG BUCK SAID',
        'D150 C82C CE6F 62D1' => 'ROIL FREE COG HUNK WAIT COCA',
        '849C 79D4 F6F5 5388' => 'FOOL STEM DONE TOOL BECK NILE',
        '8C09 92FB 2508 47B1' => 'GIST AMOS MOOT AIDS FOOD SEEM',
        '3F3B F4B4 145F D74B' => 'TAG SLOW NOV MIN WOOL KENO',
      },
      'rfc2289 md5' => {
        '9E87 6134 D904 99DD' => 'INCH SEA ANNE LONG AHEM TOUR',
        '7965 E054 36F5 029F' => 'EASE OIL FUM CURE AWRY AVIS',
        '50FE 1962 C496 5880' => 'BAIL TUFT BITS GANG CHEF THY',
        '8706 6DD9 644B F206' => 'FULL PEW DOWN ONCE MORT ARC',
        '7CD3 4C10 40AD D14B' => 'FACT HOOF AT FIST SITE KENT',
        '5AA3 7A81 F212 146C' => 'BODE HOP JAKE STOW JUT RAP',
        'F205 7539 43DE 4CF9' => 'ULAN NEW ARMY FUSE SUIT EYED',
        'DDCD AC95 6F23 4937' => 'SKIM CULT LOB SLAM POE HOWL',
        'B203 E28F A525 BE47' => 'LONG IVY JULY AJAR BOND LEE',
      },
      'rfc2289 sha1' => {
        'BB9E 6AE1 979D 8FF4' => 'MILT VARY MAST OK SEES WENT',
        '63D9 3663 9734 385B' => 'CART OTTO HIVE ODE VAT NUT',
        '87FE C776 8B73 CCF9' => 'GAFF WAIT SKID GIG SKY EYED',
        'AD85 F658 EBE3 83C9' => 'LEST OR HEEL SCOT ROB SUIT',
        'D07C E229 B5CF 119B' => 'RITE TAKE GELD COST TUNE RECK',
        '27BC 7103 5AAF 3DC6' => 'MAY STAR TIN LYON VEDA STAN',
        'D51F 3E99 BF8E 6F0B' => 'RUST WELT KICK FELL TAIL FRAU',
        '82AE B52D 9437 74E4' => 'FLIT DOSE ALSO MEW DRUM DEFY',
        '4F29 6A74 FE15 67EC' => 'AURA ALOE HURL WING BERG WAIT',
      },
      'rfc 1751' => {
        'EB33 F77E E73D 4053' => 'TIDE ITCH SLOW REIN RULE MOT',
        'CCAC 2AED 5910 56BE 4F90 FD44 1C53 4766' =>
          'RASH BUSH MILK LOOK BAD BRIM AVID GAFF BAIT ROT POD LOVE',
        'EFF8 1F9B FBC6 5350 920C DD74 16DE 8009' =>
          'TROD MUTE TAIL WARM CHAR KONG HAAG CITY BORE O TEAL AWL',
      }
    }

    # from RFC 2289
    ParityTest = {
      'FOWL KID MASH DEAD DUAL OAF' => true,
      'FOWL KID MASH DEAD DUAL NUT' => false,
      'FOWL KID MASH DEAD DUAL O' => false,
      'FOWL KID MASH DEAD DUAL OAK' => false,
    }
  end
end
