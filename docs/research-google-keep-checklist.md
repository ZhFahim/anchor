# Research: perilaku checklist Google Keep (sub-item dan checked item)

Date: 2026-11-16, WITA (UTC+8).
Metode: web search dan fetch via mcpproxy (`exa:web_search_exa`, `exa:web_fetch_exa`).
Tidak ada perubahan kode produk. Tidak ada uji manual di aplikasi Keep.

## Ringkasan jawaban

1. Keep punya indent (satu item bergeser ke kanan), bukan struktur pohon penuh.
2. Centang item parent **ikut mencentang semua item yang di-indent di bawahnya**.
3. Checked item: pindah ke bagian "Checked items" di bawah jika setelan
   "Move checked items to the bottom" aktif; jika tidak, tetap di tempat.
   Kontrol collapse ada (panah bawah), terdokumentasi resmi hanya untuk Wear OS.
4. Checked item yang ada open item sesudahnya: tetap di posisi relatifnya di
   dalam urutan list, tidak menyusun ulang open item. Tidak ada sumber resmi
   yang menyebut kasus checked-item-di-tengah secara eksplisit.

## Sumber

| Klaim | Sumber | Status |
| --- | --- | --- |
| Membuat list, menandai item, reorder item | https://support.google.com/keep/answer/6395451?co=GENIE.Platform%3DDesktop&hl=en | Resmi |
| Indent item: drag ke kanan; item pertama tidak bisa di-indent | https://support.google.com/keep/answer/6395451?co=GENIE.Platform%3DDesktop&hl=en | Resmi |
| Setelan "Move checked items to the bottom" (web + Android) | https://support.google.com/keep/answer/6358550?co=GENIE.Platform%3DDesktop&hl=en | Resmi |
| Rekomendasi uncheck "Move checked items to the bottom" agar urutan tetap | https://support.google.com/keep/answer/16914649?hl=en | Resmi |
| Hide checked items: tap Down arrow; Reload untuk uncheck semua | https://support.google.com/wearos/answer/7664632 | Resmi (Wear OS saja) |
| Rich text (bold, H1, H2) di Keep Android, lalu web | https://workspaceupdates.googleblog.com/2023/08/google-keep-notes-android-rich-text-formatting.html | Resmi (release notes) |
| Parent dicentang → semua subtask ikut; subtask dicentang → hanya item itu pindah | https://9to5google.com/2018/06/08/google-keep-subtasks/ | Tidak resmi (media) |
| Mencentang heading H1/H2 tidak mencentang item di bawahnya; hanya indent yang mengelompokkan | https://www.androidpolice.com/google-keep-notes-formatting-doesnt-help-lists/ | Tidak resmi (media, uji langsung) |
| Bagian "Checked" di bawah + panah collapse + "Delete checked items" | https://webapps.stackexchange.com/questions/44228/hide-completed-list-items-in-google-keep | Tidak resmi (komunitas) |

## 1. Apakah Keep mendukung checklist bersarang?

Ya, tetapi terbatas: **indent satu arah**, bukan tree.

- Sumber resmi hanya menyebut "Indent a list item": drag item ke kanan
  (desktop: tahan `Move`, geser ke kanan), undo dengan drag ke kiri.
  Batasan resmi: item pertama tidak bisa di-indent.
  https://support.google.com/keep/answer/6395451?co=GENIE.Platform%3DDesktop&hl=en
- Tidak ada sumber resmi yang menyebut jumlah level indent maksimum, tombol
  Tab/Shift+Tab sebagai indent, atau istilah "nested"/"sub-item" di Help Center.
  Keyboard shortcut yang terdokumentasi untuk checkbox hanya
  `Ctrl+Shift+8` (toggle checkboxes).
- Fitur indent masuk Keep lewat rollout 2018 (Android 4.1.211 dan web).
  Ini pemberitaan media, bukan release notes resmi Google:
  https://9to5google.com/2018/06/08/google-keep-subtasks/
- Heading H1/H2 dari rich text formatting **bukan** pengganti nesting. Heading
  tetap dapat checkbox, dan mencentang heading tidak menyentuh item lain.
  Uji langsung (media): https://www.androidpolice.com/google-keep-notes-formatting-doesnt-help-lists/
  Fitur format: https://workspaceupdates.googleblog.com/2023/08/google-keep-notes-android-rich-text-formatting.html

Kesimpulan bagian ini: model Keep = list flat + indent visual. Item parent dan
child diperlakukan sebagai satu grup hanya selama relasi indent itu ada.

## 2. Apakah sub-item ikut tercentang saat parent dicentang?

Ya. Sumber yang ada hanya media, tidak ada Help Center yang menyatakannya:

> "Marking a main task as complete will apply the same state to all subtasks
> underneath, while marking a subtask will only move that item to the bottom
> 'Checked items' section of the note. When reordering a main task, the
> subtasks below will also move. However, rearranging a subtask will
> automatically make it a full task."

— https://9to5google.com/2018/06/08/google-keep-subtasks/ (2018-06-08)

Konsekuensi penting untuk Anchor:

- Cascade hanya satu arah: parent → child. Child tidak cascade ke atas.
- Group anak ditentukan oleh indent, bukan oleh urutan setelah heading.
- Mengubah indent sebuah child melepas hubungan itu ("make it a full task").

Perilaku ini tidak dikonfirmasi Help Center. Jika Anchor ingin meniru Keep,
perilaku ini harus dianggap "perilaku historis yang dilaporkan media", dan
sebaiknya diuji manual di build Keep terbaru sebelum dijadikan patokan.

## 3. Checked item: pindah, disembunyikan, atau tetap di tempat?

Tiga hal berbeda, dan sumber resmi hanya menutup dua di antaranya.

a. Pindah ke bawah — ada kontrol resmi.

- Help Center: "Move checked items to the bottom of a list" adalah setelan
  global di Settings (web: Settings → List behavior; Android: Menu → Settings).
  https://support.google.com/keep/answer/6358550?co=GENIE.Platform%3DDesktop&hl=en
- Help Center screen reader menyarankan uncheck setelan ini "to maintain the
  order of checklist items after they're checked".
  https://support.google.com/keep/answer/16914649?hl=en
  Jadi default Keep adalah **pindah ke bawah**, dan user bisa memilih **tetap di
  tempat**.

b. Collapse / hide — kontrol resmi hanya terdokumentasi di Wear OS.

- Wear OS: "To hide checked items, tap the Down arrow."
  https://support.google.com/wearos/answer/7664632
- Untuk web dan Android, Help Center tidak menyebut collapse checked items.
  Bukti collapse di web hanya dari komunitas: bagian terpisah berlabel
  "Checked" dengan panah yang menutup seluruh bagian, plus aksi
  "Delete checked items".
  https://webapps.stackexchange.com/questions/44228/hide-completed-list-items-in-google-keep
  Ini tidak resmi. Perlakukan sebagai indikasi, bukan spesifikasi.

c. Tetap di tempat — hanya jika user mematikan setelan (a).

Kesimpulan: yang pasti secara resmi = setelan pindah/tidak pindah. Collapse
checked items = ada di Wear OS (resmi), kemungkinan ada di web/Android
(tidak resmi).

## 4. Checked item yang ada open item sesudahnya

Tidak ada sumber resmi maupun tidak resmi yang membahas kasus ini secara
eksplisit. Yang bisa disimpulkan dari perilaku yang terdokumentasi:

- Dengan "Move checked items to the bottom" aktif, checked item dikeluarkan dari
  urutan list dan masuk bagian checked, sehingga open item sesudahnya naik satu
  posisi. Open item tidak pernah dipindah oleh aksi mencentang.
- Dengan setelan mati, checked item tetap di posisinya di antara open item,
  dan urutan tidak berubah sama sekali
  (https://support.google.com/keep/answer/16914649?hl=en).
- Untuk grup indent: mencentang parent mencentang seluruh anak, dan (menurut
  sumber media) hanya item yang dicentang manual yang masuk bagian checked.
  Perilaku grup anak saat hanya sebagian dicentang tidak terdokumentasi.

Status klaim ini: inferensi, bukan kutipan. Perlu uji manual.

## Rekomendasi untuk Anchor

1. Pakai setelan eksplisit "move checked items to the bottom" (default on),
   bukan perilaku hardcode. Ini satu-satunya bagian yang punya dasar resmi.
2. Jangan pakai heading sebagai pengelompok checklist. Group anak harus dari
   indent, seperti Keep.
3. Cascade parent → child saat mencentang parent, searah saja.
4. Untuk collapse checked item, jadikan kontrol user (collapse/expand), karena
   Keep sendiri tidak konsisten antar platform.

## Yang belum diverifikasi

- Jumlah maksimum level indent di Keep saat ini.
- Perilaku collapse checked items di Keep web dan Android versi terbaru.
- Perilaku grup indent yang dicentang sebagian.
- Apakah Android Police dan 9to5Google masih akurat untuk build 2026.