# TODO

- [x] Add performance tests
- [x] Add possibility of detecting colors and wrapping for other scripts
- [x] bats -T test/ -j $(nproc --ignore 2)
- [x] Upstream README.md from project
- [x] Implement dynamic terminal width detection (checks width before each message display)
- [x] Debug and fix test in test/10_terminal_width_update_tests.bats - "Consecutive commands use current terminal width" (now passing)
- [] Identify parts of lib_msg.sh that have no tests and implement them
- [] Fix length bug for progress bar: doesn't take into account the progress number taking space (" 100%" takes space, and " 10%" also takes space but has one less character)
- [] Identify where the documentation is clear enough an correct it to be more concise (but don't overdo it)
- [] Revisit lib_msg.sh functions that use tr or any other non-shell intergrated commands --- we want to get rid of them and have only shell-only implementation