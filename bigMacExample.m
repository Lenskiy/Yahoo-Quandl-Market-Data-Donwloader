%% Big Mac in USD vs Big Mac in Gold 
% Download the data
initDate = '1-Jan-2000';
bigmac_quanl_raw = getMarketDataViaQuandl('ECONOMIST/BIGMAC_USA', initDate);
bigmac_quanl= timeseries([bigmac_quanl_raw.local_price], datestr(bigmac_quanl_raw(:,1).Date)); %
bigmac_quanl.TimeInfo.Format = "dd-mm-yyyy";

oz_in_grams = 31.1034768;
gold_yahoo_raw = getMarketDataViaYahoo('GC=F', initDate);
gold_yahoo_ts = timeseries([gold_yahoo_raw.Close/oz_in_grams], datestr(gold_yahoo_raw.Date));
gold_yahoo_ts.TimeInfo.Format = "dd-mm-yyyy";


% match dates
for k = 1:size(bigmac_quanl_raw,1)
    [~, ind] = min(abs(datenum(gold_yahoo_raw.('Date')(:)) - datenum(bigmac_quanl_raw.Date(k))));
    bigmac_price_in_gold(k) = bigmac_quanl_raw.local_price(k)/gold_yahoo_ts.Data(ind);
end


bigmac_price_in_gold_ts = timeseries(bigmac_price_in_gold, datestr(bigmac_quanl_raw(:,1).Date));
bigmac_price_in_gold_ts.TimeInfo.Format = "dd-mm-yyyy";

% plot
figure('color', 'white');
yyaxis left
plot(bigmac_quanl, 'linewidth', 2), hold on;
ylabel('USD')
yyaxis right
plot(bigmac_price_in_gold_ts, 'linewidth', 2);
ylabel('g of Gold')
title('Big Mac');
grid on, grid minor


%% Big Mac in USD vs Big Mac in BTC 
initDate = '2014-09-17';
btc_yahoo_raw = getMarketDataViaYahoo('BTC-USD', initDate);

bigmac_quanl_raw = getMarketDataViaQuandl('ECONOMIST/BIGMAC_USA', initDate);
bigmac_quanl= timeseries([bigmac_quanl_raw.local_price], datestr(bigmac_quanl_raw(:,1).Date)); %
bigmac_quanl.TimeInfo.Format = "dd-mm-yyyy";

for k = 1:size(bigmac_quanl_raw,1)
    [val, ind] = min(abs(datenum(btc_yahoo_raw.('Date')(:)) - datenum(bigmac_quanl_raw.Date(k))));
    bigmac_price_in_btc(k) = bigmac_quanl_raw.local_price(k)/btc_yahoo_raw.Close(ind);
end

bigmac_price_in_btc_ts = timeseries(bigmac_price_in_btc, datestr(bigmac_quanl_raw(:,1).Date));
bigmac_price_in_btc_ts.TimeInfo.Format = "dd-mm-yyyy";
bigmac_price_in_btc_ts.DataInfo.Units = "BTC";


figure('color', 'white');
yyaxis left
plot(bigmac_quanl, 'linewidth', 2), hold on;
ylabel('USD')
yyaxis right
plot(bigmac_price_in_btc_ts, 'linewidth', 2);
ylabel('BTC')
title('Big Mac')
grid on
grid minor


