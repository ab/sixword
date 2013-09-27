require_relative '../rspec_helper'

describe Sixword::Hex do
  TestCases = {
    "\x73\xe2\x16\xb5\x36\x3f\x23\x77" => [
      "73e216b5363f2377",
      "73E2 16B5 363F 2377",
      "73:e2:16:b5:36:3f:23:77",
    ],
    "\xfe\xfb\x90\x3d\x12\x59\x36\xee" => [
      "fefb903d125936ee",
      "FEFB 903D 1259 36EE",
      "fe:fb:90:3d:12:59:36:ee",
    ],
    "\x41\x2e\xb9\x92\xe8\x34\xe9\x90" => [
      "412eb992e834e990",
      "412E B992 E834 E990",
      "41:2e:b9:92:e8:34:e9:90",
    ],
    "\x76\x55\x69\x21\x5c\x74\x1b\xda" => [
      "765569215c741bda",
      "7655 6921 5C74 1BDA",
      "76:55:69:21:5c:74:1b:da",
    ],
    "\x62\xec\x83\xdf\x92\x2f\x8a\x7d" => [
      "62ec83df922f8a7d",
      "62EC 83DF 922F 8A7D",
      "62:ec:83:df:92:2f:8a:7d",
    ],
    "\xe2\x65\x2a\x67\xe8\x32\x41\x19" => [
      "e2652a67e8324119",
      "E265 2A67 E832 4119",
      "e2:65:2a:67:e8:32:41:19",
    ],
    "\xd2\x6b\x73\x44\x17\xad\x7f\x93" => [
      "d26b734417ad7f93",
      "D26B 7344 17AD 7F93",
      "d2:6b:73:44:17:ad:7f:93",
    ],
    "\xc5\x3c\xab\x0e\x0c\xf5\x2a\xe8" => [
      "c53cab0e0cf52ae8",
      "C53C AB0E 0CF5 2AE8",
      "c5:3c:ab:0e:0c:f5:2a:e8",
    ],

    "\x34\x59\xa1\x13\x01\x94\xc3\xf6\xe8\xa9\xec\xf6\x44\xb5\xba\x41" => [
      "3459a1130194c3f6e8a9ecf644b5ba41",
      "3459 A113 0194 C3F6 E8A9 ECF6 44B5 BA41",
      "34:59:a1:13:01:94:c3:f6:e8:a9:ec:f6:44:b5:ba:41",
    ],
    "\x8e\x93\x05\x97\xec\x03\x41\x9d\x13\x1c\x05\x7a\x6a\xa9\xc5\x73" => [
      "8e930597ec03419d131c057a6aa9c573",
      "8E93 0597 EC03 419D 131C 057A 6AA9 C573",
      "8e:93:05:97:ec:03:41:9d:13:1c:05:7a:6a:a9:c5:73",
    ],
    "\xc6\xb4\x10\xe9\x26\x71\x1a\x7c\x4f\x67\x98\xf9\x92\x0e\xdf\x4c" => [
      "c6b410e926711a7c4f6798f9920edf4c",
      "C6B4 10E9 2671 1A7C 4F67 98F9 920E DF4C",
      "c6:b4:10:e9:26:71:1a:7c:4f:67:98:f9:92:0e:df:4c",
    ],
    "\x83\x6a\x14\xd4\x0b\xf0\xc6\xed\xb5\xa8\x1f\xb7\xc0\xcc\xc5\x22" => [
      "836a14d40bf0c6edb5a81fb7c0ccc522",
      "836A 14D4 0BF0 C6ED B5A8 1FB7 C0CC C522",
      "83:6a:14:d4:0b:f0:c6:ed:b5:a8:1f:b7:c0:cc:c5:22",
    ],
    "\x26\xb8\xdf\xd0\x00\x35\x98\xff\xec\x95\xc3\xa1\x1e\x64\x97\x08" => [
      "26b8dfd0003598ffec95c3a11e649708",
      "26B8 DFD0 0035 98FF EC95 C3A1 1E64 9708",
      "26:b8:df:d0:00:35:98:ff:ec:95:c3:a1:1e:64:97:08",
    ],
    "\xd9\xff\xcb\x22\xe5\x2e\x92\x0c\xfd\x45\xcb\x0c\x18\x18\x08\x10" => [
      "d9ffcb22e52e920cfd45cb0c18180810",
      "D9FF CB22 E52E 920C FD45 CB0C 1818 0810",
      "d9:ff:cb:22:e5:2e:92:0c:fd:45:cb:0c:18:18:08:10",
    ],
    "\x73\x13\xc0\x90\x96\xd1\x5b\xbd\x10\x04\x69\x34\xf0\xbe\xf9\x60" => [
      "7313c09096d15bbd10046934f0bef960",
      "7313 C090 96D1 5BBD 1004 6934 F0BE F960",
      "73:13:c0:90:96:d1:5b:bd:10:04:69:34:f0:be:f9:60",
    ],
    "\x18\x3b\xa9\x75\x54\x57\xf9\x5d\x00\x13\x5e\x3c\x87\x9f\x1c\x17" => [
      "183ba9755457f95d00135e3c879f1c17",
      "183B A975 5457 F95D 0013 5E3C 879F 1C17",
      "18:3b:a9:75:54:57:f9:5d:00:13:5e:3c:87:9f:1c:17",
    ],
  }

  it 'should decode and encode random hex strings correctly' do
    TestCases.each do |binary, hexes|
      lower, finger, colons = hexes
      Sixword::Hex.encode(binary).should == lower
      Sixword::Hex.decode(lower).should == binary
    end
  end

  it 'should decode and encode random hex fingerprints correctly' do
    TestCases.each do |binary, hexes|
      lower, finger, colons = hexes
      Sixword::Hex.encode_fingerprint(binary).should == finger
      Sixword::Hex.decode(finger).should == binary
    end
  end

  it 'should decode and encode random colon hexes correctly' do
    TestCases.each do |binary, hexes|
      lower, finger, colons = hexes
      Sixword::Hex.encode_colons(binary).should == colons
      Sixword::Hex.decode(colons).should == binary
    end
  end

  it 'should accept all valid hex characters' do
    Sixword::Hex.valid_hex?('abcdefABCDEF0123456789').should == true
  end

  it 'should reject invalid hex characters' do
    'g'..'z'.each do |c|
      Sixword::Hex.valid_hex?(c).should == false
    end
    'G'..'Z'.each do |c|
      Sixword::Hex.valid_hex?(c).should == false
    end
  end
end
