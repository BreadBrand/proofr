# proofr
A Recipe parsing engine

The project is using Zig 0.16.0

## Road Map:
- [x] 00 Repo setup + Hello World HTTP server
- [x] 01 types.zig 
- [x] 02 HTTP skeleton: handler.zig, arena allocator, CORS, OPTIONS
- [x] 03 Stage 1a: input validation + HTML stripping + entity unescaping
- [x] 04 Stage 1b: Markdown stripping, smart quotes, unicode fractions, mixed numbers
- [ ] 05 Stage 1c: artifact stripping, (browser, recipe UI, URLS, CTAs)
- [ ] 06 Stage 1d: nutrition markers, metadata expansion, baker% strip, temp annotation strip
- [ ] 07 units.zig: unit table, matching, canonicalisation
- [ ] 08 Stage 2a: sections.zig skeleton - state machine, section keywords, enum + switch
- [ ] 09 Stage 2b: subsection header detection, ingredient groups, phase routing
- [ ] 10 Stage 2c: title detection, description, notes buffer, nutrition buffer
- [ ] 11 Stage 3a: bullet strip, yeast alternatives, no-quantity patterns, quantity extraction
- [ ] 12 Stage 3b: unit matching, alternate measurement strip, name cleaning
- [ ] 13 Stage 3c: confidence scoring per ingredient + deduplication
- [ ] 14 Stage 4: insructions.zig - prefix strip, subsection headers, confidence scoring
- [ ] 15 Stage 5: metadata.zig - time fields, servings, notes, nutrition
- [ ] 16 Stage confidence.zig: section means, title scoring, flags
- [ ] 17 parser.zig: pipeline orchestration + complete handler wiring
- [ ] 18 Integration tests: 10 recipe fixtures + AC-1 through AC-10
- [ ] 19 Deployment: --port flag, systemd unit, Cloudflare tunnel

## Dependency list:
- zig fetch https://github.com/karlseguin/http.zig/commit/master.tar.gz
