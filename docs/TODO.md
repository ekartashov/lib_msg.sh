# TODO

- [x] Add performance tests
- [x] Add possibility of detecting colors and wrapping for other scripts
- [x] bats -T test/ -j $(nproc --ignore 2)
- [x] Upstream README.md from project
- [x] Implement dynamic terminal width detection (checks width before each message display)
- [x] Debug and fix test in test/10_terminal_width_update_tests.bats - "Consecutive commands use current terminal width" (now passing)
- [X] Identify parts of lib_msg.sh that have no tests and implement them
- [X] Fix length bug for progress bar: doesn't take into account the progress number taking space (" 100%" takes space, and " 10%" also takes space but has one less character)
- [] Identify where the documentation is clear enough an correct it to be more concise (but don't overdo it)
- [x] Revisit lib_msg.sh functions that use tr or any other non-shell intergrated commands --- we want to get rid of them and have only shell-only implementation
- [X] Reorganize tests so they are numbered correctly while letting performance tests be last (like set them to 50, so there's place for other test files to be added)
- [X] Update examples/public_api_demo.sh to use all the new functionality used in lib_msg.sh while updating the documentation to be coherent with the changesz
- [] Add max wrap length (to prevent stalls)
- [] Check wether further optimizations are possible
- [] Check wether optional external cmds is feasible