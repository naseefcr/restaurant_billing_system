# Restaurant Billing System - Functional Testing Guide

## Overview
This guide provides comprehensive testing scenarios to ensure the restaurant billing system works correctly in various real-world conditions.

## Test Environment Setup
- **Cashier App**: Install on one mobile device
- **Waiter App**: Install on one or more mobile devices
- **Network**: All devices on the same WiFi network
- **Testing Duration**: Allow 2-3 hours for complete testing

## 1. Network Discovery & Connection Tests

### Test 1.1: Basic Discovery
**Steps:**
1. Start cashier app → verify "Server Running" status
2. Start waiter app → should auto-discover server
3. Verify connection established automatically

**Expected Result:**
- Waiter app shows "Online: 1" servers
- Connection status shows "Connected"
- Server IP matches cashier app IP

### Test 1.2: Manual Connection
**Steps:**
1. Stop discovery on waiter app
2. Enter cashier app IP manually
3. Tap "Add Server"

**Expected Result:**
- Connection established successfully
- All data synced properly

### Test 1.3: Network Interruption Recovery
**Steps:**
1. Establish connection between apps
2. Turn off WiFi on cashier app device
3. Wait 30 seconds
4. Turn WiFi back on
5. Tap refresh button on waiter app

**Expected Result:**
- Waiter app detects disconnection
- Auto-reconnects when cashier comes back online
- Manual refresh button works
- Discovery shows server again

### Test 1.4: IP Address Change
**Steps:**
1. Establish connection
2. Change cashier app to different WiFi network
3. Note new IP address
4. Wait for waiter app to detect change
5. Use manual connection with new IP

**Expected Result:**
- Waiter app eventually detects old connection is stale
- Manual connection with new IP works
- Data sync resumes

## 2. Real-time Synchronization Tests

### Test 2.1: Table Status Sync
**Steps:**
1. Connect both apps
2. Change table status in cashier app (available → occupied)
3. Verify change appears in waiter app immediately
4. Change status in waiter app
5. Verify change appears in cashier app

**Expected Result:**
- Changes appear within 2-3 seconds
- Color coding updates correctly
- No data loss or corruption

### Test 2.2: Order Creation Sync
**Steps:**
1. Create order in waiter app
2. Submit order
3. Check Orders tab in cashier app
4. Verify order appears in waiter app's Orders tab

**Expected Result:**
- Order appears in cashier app immediately
- Order appears in waiter app's order list
- All order details are correct

### Test 2.3: Connection Health Monitoring
**Steps:**
1. Establish connection
2. Observe connection health indicator
3. Simulate network issue (airplane mode for 30 seconds)
4. Restore connection
5. Check health indicator recovery

**Expected Result:**
- Health indicator shows green (healthy)
- Shows orange/red during network issues
- Returns to green after recovery

## 3. Data Persistence & Integrity Tests

### Test 3.1: Server Restart Recovery
**Steps:**
1. Create several orders and table changes
2. Force close cashier app
3. Restart cashier app
4. Verify all data is preserved
5. Check waiter app reconnects automatically

**Expected Result:**
- All data preserved in cashier app
- Waiter app reconnects within 30 seconds
- Data sync resumes correctly

### Test 3.2: Client Reconnection
**Steps:**
1. Establish connection
2. Force close waiter app
3. Restart waiter app
4. Verify automatic reconnection
5. Check data sync

**Expected Result:**
- Waiter app reconnects automatically
- Fresh data pulled from server
- Real-time sync works

### Test 3.3: Multiple Orders per Table
**Steps:**
1. Select same table in waiter app
2. Create multiple orders
3. Verify order selection dialog works
4. Check all orders appear in cashier app

**Expected Result:**
- Order selection dialog shows all orders
- Each order is distinct and complete
- Cashier app shows all orders for table

## 4. User Experience Tests

### Test 4.1: Connection Status Visibility
**Steps:**
1. Monitor connection indicators
2. Test various connection states
3. Verify user feedback is clear

**Expected Result:**
- Clear visual indicators for connection state
- Appropriate colors (green/orange/red)
- Helpful tooltips and messages

### Test 4.2: Error Handling
**Steps:**
1. Test various error scenarios
2. Verify error messages are user-friendly
3. Check recovery mechanisms

**Expected Result:**
- Clear error messages
- Suggested actions for recovery
- No app crashes

### Test 4.3: Performance Under Load
**Steps:**
1. Create multiple orders quickly
2. Change table statuses rapidly
3. Test with multiple waiter apps connected

**Expected Result:**
- App remains responsive
- No significant delays
- Memory usage stable

## 5. Edge Case Tests

### Test 5.1: Rapid Network Changes
**Steps:**
1. Quickly toggle WiFi on/off multiple times
2. Switch between different WiFi networks
3. Test app behavior during transitions

**Expected Result:**
- Apps handle rapid changes gracefully
- No crashes or data corruption
- Eventually reconnect when stable

### Test 5.2: Low Battery Scenarios
**Steps:**
1. Test with devices at low battery
2. Enable battery saver mode
3. Verify apps still function

**Expected Result:**
- Apps continue to work
- May reduce discovery frequency
- No data loss

### Test 5.3: Multiple Clients
**Steps:**
1. Connect 3-4 waiter apps to one cashier app
2. Create orders from different clients
3. Test real-time sync across all apps

**Expected Result:**
- All apps receive updates
- No conflicts or data corruption
- Smooth multi-client operation

## 6. Security & Network Tests

### Test 6.1: Network Security
**Steps:**
1. Test on different network types (home, public, hotspot)
2. Verify connection security
3. Test with network restrictions

**Expected Result:**
- Apps work on various networks
- No security vulnerabilities
- Appropriate error handling for restrictions

### Test 6.2: Data Validation
**Steps:**
1. Test with invalid data inputs
2. Verify server-side validation
3. Check client-side validation

**Expected Result:**
- Invalid data rejected gracefully
- Appropriate error messages
- No server crashes

## 7. Recovery & Stress Tests

### Test 7.1: Extended Runtime
**Steps:**
1. Leave apps running for 4-6 hours
2. Perform regular operations
3. Monitor memory usage and performance

**Expected Result:**
- Apps remain stable
- No memory leaks
- Performance stays consistent

### Test 7.2: Database Stress
**Steps:**
1. Create 100+ orders
2. Test app performance
3. Verify data integrity

**Expected Result:**
- App handles large datasets
- Performance remains acceptable
- No data corruption

## Testing Checklist

### Before Testing
- [ ] Both apps installed and updated
- [ ] Devices on same network
- [ ] Test environment prepared
- [ ] Backup any important data

### During Testing
- [ ] Document all issues found
- [ ] Take screenshots of problems
- [ ] Note exact steps to reproduce
- [ ] Test on different devices/OS versions

### After Testing
- [ ] All major scenarios tested
- [ ] Issues documented and prioritized
- [ ] Performance metrics recorded
- [ ] User experience feedback captured

## Common Issues & Solutions

### Issue: Discovery Not Working
**Solution:** 
- Check firewall settings
- Verify UDP port 8082 is open
- Try manual refresh button
- Check network connectivity

### Issue: Real-time Sync Failed
**Solution:**
- Check WebSocket connection health
- Use connection refresh button
- Verify server is still running
- Check network stability

### Issue: Data Not Persisting
**Solution:**
- Verify database permissions
- Check storage space
- Restart apps if needed
- Check for app updates

## Performance Benchmarks

### Expected Response Times
- Discovery: < 5 seconds
- Connection: < 3 seconds
- Real-time sync: < 2 seconds
- Order submission: < 1 second

### Memory Usage
- Cashier app: < 150MB
- Waiter app: < 100MB
- No memory leaks over 4 hours

### Network Usage
- Discovery: ~1KB every 15 seconds
- Real-time sync: ~500 bytes per update
- Order submission: ~2-5KB per order

## Conclusion

This comprehensive testing guide ensures the restaurant billing system works reliably in real-world conditions. Regular testing with these scenarios will help maintain system quality and user satisfaction.

For any issues found during testing, please document them with:
1. Steps to reproduce
2. Expected vs actual behavior
3. Device/OS information
4. Network conditions
5. Screenshots or videos if helpful