// Konfigurace otevírací/zavírací animace panelu.
// Uprav hodnoty tady, shell.qml je jen importuje.

// @ts-ignore
.import "styleConfig.js" as Styles;

var velocityCap = 800;
// |dx jednotek/s|, které se považují za "rychlé" máchnutí (flick).
// Rychlost nad tímto stropem se dál nezapočítává (normalizuje se na 1.0).

var overdragCap = 30;
// Jak daleko za okraj (přetažení/rubber-band) se počítá jako "dlouhé" gesto -
// stejně jako velocityCap, ale pro vzdálenost místo rychlosti.

var bounceCurveExponent = 6;
// Mocnina, na kterou se umocní normalizovaná intensity (viz shell.qml).
// Čím vyšší číslo, tím déle zůstává bounce téměř neviditelný pro běžná
// (pomalá/krátká) gesta a projeví se až u opravdu rychlých/dlouhých.

var maxOvershoot = 1.6;
// Maximální amplituda OutBack easing (Qt "overshoot") při intensity = 1.0.
// 0 = žádný bounce, vyšší číslo = výraznější přestřelení přes cíl.

var openDuration = 320;
// Délka (ms) animace při otevírání panelu.

var closeDuration = 220;
// Délka (ms) animace při zavírání panelu - zavírání nikdy nemá bounce
// (viz shell.qml, overshoot se u zavírání vždy nastaví na 0).

var flickVelocityThreshold = 120;
// Když |velocity| překročí tuto hodnotu, o otevření/zavření rozhoduje směr
// (znaménko) rychlosti, ne aktuální pozice panelu - takže i krátké rychlé
// máchnutí panel spolehlivě otevře/zavře.

var openDragFraction = 0.3;
// Jak velkou část panelWidth stačí (pomalu, bez flicku) odtáhnout, aby se
// panel při puštění prstů otevřel. 0.3 = stačí odtáhnout 30 % šířky panelu.
// Nižší hodnota = kratší gesto potřeba k otevření.

var overdragAmount = 35;
// O kolik jednotek smí currentX přetéct za oba okraje (0 a panelWidth) při
// rubber-band efektu během tažení. Stejná hodnota pro obě strany.

var axisTouchThreshold = 6;
// Kolik jednotek (součet dx/dy za celé gesto) musí osa nastřádat, aby se
// počítala jako "opravdu tažená" tímto gestem - viz shell.qml "panels"
// handler. Brání tomu, aby drobný diagonální šum na ose, kterou uživatel
// vůbec nechtěl ovládat (např. při čistě svislém flicku), omylem spustil
// souboj o to, který panel zůstane otevřený.

// --- Rozměry panelů a úchytu ---
// Sem patří všechny velikostní konstanty, aby byly na jednom místě spolu
// s animačním laděním výše.

var panelWidth = 375;
// Šířka pravého (RightPanel) panelu v px, když je plně otevřený.

var panelHeight = 300;
// Výška horního (TopPanel) panelu v px, když je plně otevřený.

var topPanelWidth = 500;
// Šířka horního panelu v px, když je plně otevřený. Panel je zarovnaný
// k pravému okraji obrazovky (viz shell.qml).

var cornerTabWidth = 75;
// Šířka "úchytu" (rohové destičky s hodinami) v px.

var cornerTabHeight = 34;
// Výška úchytu v px.

var cornerTabRadius = Styles.round;
// Poloměr zaoblení spodního levého rohu úchytu.

var seamOverlap = 1;
// O kolik px se úchyt překrývá s panelem, aby mezi nimi nebyla vidět
// jednopixelová mezera způsobená zaokrouhlováním.
