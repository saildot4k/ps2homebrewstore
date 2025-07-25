PS2 RDRAM TEST (BASED ON TESTMODE ) krat0s

This is a simple test app for your PS2 RDRAM.

It is an open source version of the test performed by rom0:TESTMODE.

When launched TESTMODE waits for a test code from the mechacon and for the normal user there is no way to do that.
Even if it would, to view the result you need to have a EE sio cable attached etc..

There can be many general RAM tests used for the PS2 but using the original way of testing seems the best option.

The output of test will be completely like the output of TESTMODE.

Run the app, wait a few seconds then check if have only OK. If so, and the final status is OK for A and B then your RAM is ok.

If you see any NG (NO GOOD) then your RDRAM is starting to FAIL.

Simple, lightweight and ugly!

Source code included (trying to be as most accurate and identical to TESTMODE code)

Happy Birthday PS2!

Modified by El_isra to use colored font. Making it easy to spot issues for those who use composite cable on modern TVs (wich causes scr_printf to look terrible).

