function IP = getLoopbackIP()
%

%   Copyright 2018-2020 The MathWorks, Inc.

nis = matlab.net.internal.NetworkInterface.list;
ni = nis([nis.IsLoopback]);
ni = ni(1); % just in case there is more than one...
lo = ni.InetAddresses([ni.InetAddresses.Version]==4);
if isempty(lo)
    lo = ni.InetAddresses;
end
lo = lo(1); % just in case there is more than one...
IP = convertStringsToChars(string(lo));

end
