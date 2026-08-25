function evaluate_average_precision(detector, test_combined_datastore)
try 
    results = detect(detector, test_combined_datastore.UnderlyingDatastores{1,1});
    [ap, recall, precision] = evaluateDetectionPrecision(results, test_combined_datastore.UnderlyingDatastores{1,2});
    
catch 
    results = detect(detector, test_combined_datastore);
    [ap, recall, precision] = evaluateDetectionPrecision(results, test_combined_datastore);
end
figure;
    plot(recall, precision);
    grid on
    title(sprintf('Average precision = %.3f', ap))
    
end