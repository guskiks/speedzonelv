# GitHub augšupielāde no Windows

## Vienkāršākais variants — GitHub mājaslapā

1. Atver <https://github.com/new>.
2. Izveido jaunu repozitoriju, piemēram, `SpeedZoneLV`.
3. Izvēlies **Public** (GitHub publiskajiem repozitorijiem macOS Actions
   būvēšanas minūtes ir bez maksas).
4. Šajā mapē atrodas jau viss nepieciešamais. GitHub augšupielādē **mapes
   saturu**, nevis ZIP failu:

   ```text
   .github/
   Config/
   docs/
   Shared/
   SpeedZoneLV.xcodeproj/
   SpeedZoneLV/
   Widgets/
   .gitignore
   project.yml
   README.md
   TODO.md
   ```

5. Repozitorijā spied **Add file → Upload files**.
6. Ievelc visus šos failus un mapes logā. Pārliecinies, ka `.github` mape ar
   `workflows/build.yml` arī ir augšupielādēta.
7. Apakšā ieraksti commit ziņu, piemēram, `Initial SpeedZone LV project`, un
   spied **Commit changes**.

GitHub pats neizpako ZIP failu, tāpēc ZIP failu augšupielādēt nevajag.

## Pēc augšupielādes

1. Atver repozitorija cilni **Actions**.
2. Kreisajā pusē izvēlies **Build unsigned IPA**.
3. Spied **Run workflow** un vēlreiz **Run workflow**.
4. Pagaidi, kamēr būve beidzas ar zaļu `Success`.
5. Job lapas apakšā sadaļā **Artifacts** lejupielādē
   `SpeedZoneLV-unsigned-ipa`.

Lejupielādētais fails ir `SpeedZoneLV-unsigned.ipa`. To pēc tam Windows datorā
paraksta ar Sideloadly vai AltStore. GitHub Actions pats nevar parakstīt lietotni
ar tavu Apple ID.

## Ja izmanto GitHub Desktop

1. Instalē GitHub Desktop.
2. Izvēlies **Add → Add existing repository**.
3. Norādi šo `SpeedZoneLV` mapi.
4. Spied **Publish repository**.
5. Izvēlies repozitorija nosaukumu un publicitāti, tad publicē.
6. GitHub lapā atver **Actions** un palaid **Build unsigned IPA**.

## Ja maini kodu vēlāk

Pēc jebkurām koda vai dizaina izmaiņām augšupielādē izmainītos failus GitHub un
izveido commit uz `main`. Pēc commit GitHub Actions uzbūvē jaunu IPA. Vecā
instalētā versija iPhone pati neatjaunojas — lejupielādē jauno IPA un ielādē to
iLoader no jauna.
