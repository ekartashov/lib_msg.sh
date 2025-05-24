# TODO

- [ ] Add performance tests
- [ ] Refactor code for clarity
- [ ] Add possibility of detecting colors and wrapping for other scripts
- [ ] Add ask prompts
- [ ] May be add log levels functionality
- [ ] bats -T test/ -j $(nproc --ignore 2)
- [ ] Upstream README.md from project
- [x] Implement dynamic terminal width detection (checks width before each message display)
- [x] Debug and fix test in test/10_terminal_width_update_tests.bats - "Consecutive commands use current terminal width" (now passing)