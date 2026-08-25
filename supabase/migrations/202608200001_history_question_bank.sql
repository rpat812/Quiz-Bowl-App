alter table public.questions add column if not exists category text;
alter table public.questions add column if not exists subcategory text;
alter table public.questions add column if not exists difficulty text;
alter table public.questions add column if not exists question_type text;
alter table public.questions add column if not exists region text;
alter table public.questions add column if not exists time_period text;
alter table public.questions add column if not exists tags text[] not null default '{}';
alter table public.questions add column if not exists question text;
alter table public.questions add column if not exists options jsonb not null default '[]'::jsonb;
alter table public.questions add column if not exists correct_answer jsonb;
alter table public.questions add column if not exists explanation text;

update public.questions
set correct_answer = to_jsonb(accepted_answer)
where correct_answer is null;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'questions_difficulty_check') then
    alter table public.questions add constraint questions_difficulty_check
      check (difficulty is null or difficulty in ('easy', 'medium', 'hard'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'questions_type_check') then
    alter table public.questions add constraint questions_type_check
      check (question_type is null or question_type in ('multiple_choice', 'fill_in_the_blank', 'true_false', 'short_answer'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'questions_options_array_check') then
    alter table public.questions add constraint questions_options_array_check
      check (jsonb_typeof(options) = 'array');
  end if;
end;
$$;

with batch as (
  select *
  from jsonb_to_recordset($history$
[
  {"questionId":"HIST-0001","category":"History","subcategory":"Ancient Mesopotamia","difficulty":"easy","questionType":"multiple_choice","region":"Middle East","timePeriod":"Ancient","tags":["Babylon","law codes","Hammurabi"],"question":"Which Babylonian king commissioned one of the best-preserved law codes from the ancient world?","options":["Sargon of Akkad","Hammurabi","Nebuchadnezzar II","Ashurbanipal"],"correctAnswer":"Hammurabi","explanation":"Hammurabi ruled Babylon in the eighteenth century BCE and issued a code regulating crime, property, contracts, and family life."},
  {"questionId":"HIST-0002","category":"History","subcategory":"Ancient Greece","difficulty":"easy","questionType":"multiple_choice","region":"Western Europe","timePeriod":"Ancient","tags":["Athens","democracy","Cleisthenes"],"question":"Which Greek city-state developed a system of direct democracy associated with the reforms of Cleisthenes?","options":["Athens","Sparta","Corinth","Thebes"],"correctAnswer":"Athens","explanation":"Cleisthenes reorganized Athenian political participation around 508 BCE and helped establish its democratic institutions."},
  {"questionId":"HIST-0003","category":"History","subcategory":"Ptolemaic Egypt","difficulty":"easy","questionType":"multiple_choice","region":"North Africa","timePeriod":"Ancient","tags":["Cleopatra VII","Ptolemaic dynasty","Egypt"],"question":"Cleopatra VII was the final active ruler of which dynasty in Egypt?","options":["Twenty-sixth Dynasty","Seleucid dynasty","Julio-Claudian dynasty","Ptolemaic dynasty"],"correctAnswer":"Ptolemaic dynasty","explanation":"The Ptolemaic dynasty was founded after Alexander the Great's death and ended with Cleopatra VII in 30 BCE."},
  {"questionId":"HIST-0004","category":"History","subcategory":"Medieval England","difficulty":"easy","questionType":"multiple_choice","region":"Western Europe","timePeriod":"Medieval","tags":["Magna Carta","King John","English monarchy"],"question":"Which English king sealed the Magna Carta in 1215 after pressure from rebellious barons?","options":["Henry II","Richard I","John","Edward I"],"correctAnswer":"John","explanation":"King John sealed the Magna Carta at Runnymede, accepting written limits on royal authority and protections for baronial rights."},
  {"questionId":"HIST-0005","category":"History","subcategory":"Black Death","difficulty":"easy","questionType":"multiple_choice","region":"Global","timePeriod":"Medieval","tags":["Black Death","plague","Yersinia pestis"],"question":"Which bacterium caused the plague responsible for the Black Death?","options":["Vibrio cholerae","Yersinia pestis","Mycobacterium tuberculosis","Salmonella enterica"],"correctAnswer":"Yersinia pestis","explanation":"Yersinia pestis caused the pandemic that killed a large share of the population across Europe, Asia, and North Africa."},
  {"questionId":"HIST-0006","category":"History","subcategory":"U.S. Revolution","difficulty":"easy","questionType":"multiple_choice","region":"North America","timePeriod":"1700s","tags":["Treaty of Paris","American Revolution","independence"],"question":"Which agreement formally ended the American Revolutionary War and recognized United States independence?","options":["Treaty of Ghent","Jay Treaty","Treaty of Guadalupe Hidalgo","Treaty of Paris of 1783"],"correctAnswer":"Treaty of Paris of 1783","explanation":"The Treaty of Paris of 1783 ended the war between Britain and the United States and recognized the new nation's independence."},
  {"questionId":"HIST-0007","category":"History","subcategory":"U.S. Expansion","difficulty":"easy","questionType":"multiple_choice","region":"North America","timePeriod":"1800s","tags":["Louisiana Purchase","France","Thomas Jefferson"],"question":"The United States acquired the Louisiana Territory in 1803 from which country?","options":["France","Spain","Britain","Mexico"],"correctAnswer":"France","explanation":"Napoleon's government sold Louisiana to the United States, giving it New Orleans and vast lands west of the Mississippi."},
  {"questionId":"HIST-0008","category":"History","subcategory":"U.S. Abolitionism","difficulty":"easy","questionType":"multiple_choice","region":"United States","timePeriod":"1800s","tags":["Frederick Douglass","abolitionism","autobiography"],"question":"Which formerly enslaved abolitionist published a widely read narrative of his life in 1845?","options":["William Lloyd Garrison","John Brown","Frederick Douglass","Sojourner Truth"],"correctAnswer":"Frederick Douglass","explanation":"Frederick Douglass used his autobiography, speeches, and newspapers to expose slavery and advocate for equal citizenship."},
  {"questionId":"HIST-0009","category":"History","subcategory":"U.S. Civil War","difficulty":"easy","questionType":"multiple_choice","region":"United States","timePeriod":"1800s","tags":["Gettysburg","Civil War","Pennsylvania"],"question":"In which state was the Battle of Gettysburg fought?","options":["Virginia","Pennsylvania","Maryland","Tennessee"],"correctAnswer":"Pennsylvania","explanation":"The Battle of Gettysburg was fought in Pennsylvania in July 1863 and ended Robert E. Lee's second invasion of the North."},
  {"questionId":"HIST-0010","category":"History","subcategory":"Meiji Japan","difficulty":"easy","questionType":"multiple_choice","region":"East Asia","timePeriod":"1800s","tags":["Meiji Restoration","Japan","modernization"],"question":"The Meiji Restoration of 1868 restored imperial rule in which country?","options":["Japan","China","Korea","Thailand"],"correctAnswer":"Japan","explanation":"The Meiji Restoration ended Tokugawa rule and began rapid state-led modernization and industrialization in Japan."},
  {"questionId":"HIST-0011","category":"History","subcategory":"World War I","difficulty":"easy","questionType":"multiple_choice","region":"Eastern Europe","timePeriod":"1900-1945","tags":["Gavrilo Princip","Franz Ferdinand","Sarajevo"],"question":"Who assassinated Archduke Franz Ferdinand in Sarajevo in 1914?","options":["Leon Trotsky","Otto von Bismarck","Kaiser Wilhelm II","Gavrilo Princip"],"correctAnswer":"Gavrilo Princip","explanation":"Gavrilo Princip's assassination of Franz Ferdinand triggered the diplomatic crisis that led to World War I."},
  {"questionId":"HIST-0012","category":"History","subcategory":"World War II","difficulty":"easy","questionType":"multiple_choice","region":"Western Europe","timePeriod":"1900-1945","tags":["D-Day","Normandy","Operation Overlord"],"question":"The Allied D-Day landings of June 1944 took place in which region of France?","options":["Brittany","Alsace","Normandy","Provence"],"correctAnswer":"Normandy","explanation":"The Normandy landings opened a major Western Front and began the liberation of Western Europe."},
  {"questionId":"HIST-0013","category":"History","subcategory":"Cold War Germany","difficulty":"easy","questionType":"multiple_choice","region":"Western Europe","timePeriod":"1945-1991","tags":["Berlin Wall","Cold War","German reunification"],"question":"In what year did the Berlin Wall open, signaling the approaching end of communist rule in East Germany?","options":["1989","1968","1979","1991"],"correctAnswer":"1989","explanation":"East German authorities opened border crossings on November 9, 1989, and Germany reunified the following year."},
  {"questionId":"HIST-0014","category":"History","subcategory":"South African Apartheid","difficulty":"easy","questionType":"multiple_choice","region":"Sub-Saharan Africa","timePeriod":"Post-1991","tags":["Nelson Mandela","apartheid","South Africa"],"question":"Who became South Africa's first Black president after the country's first fully democratic national election?","options":["Desmond Tutu","Nelson Mandela","F. W. de Klerk","Thabo Mbeki"],"correctAnswer":"Nelson Mandela","explanation":"Nelson Mandela became president in 1994 after negotiations established multiracial democracy and ended apartheid rule."},
  {"questionId":"HIST-0015","category":"History","subcategory":"Late Roman Empire","difficulty":"medium","questionType":"multiple_choice","region":"Western Europe","timePeriod":"Ancient","tags":["Edict of Milan","Constantine","Christianity"],"question":"Which Roman emperor joined Licinius in issuing the Edict of Milan, which granted religious toleration in 313 CE?","options":["Diocletian","Theodosius I","Constantine I","Julian"],"correctAnswer":"Constantine I","explanation":"Constantine I and Licinius agreed on religious toleration that ended official persecution of Christians in their territories."},
  {"questionId":"HIST-0016","category":"History","subcategory":"Norman Conquest","difficulty":"medium","questionType":"multiple_choice","region":"Western Europe","timePeriod":"Medieval","tags":["Battle of Hastings","William the Conqueror","Norman England"],"question":"Which leader defeated Harold Godwinson at the Battle of Hastings in 1066?","options":["William of Normandy","Harald Hardrada","Henry Plantagenet","Alfred the Great"],"correctAnswer":"William of Normandy","explanation":"William of Normandy won at Hastings and was crowned king, beginning the Norman transformation of England."},
  {"questionId":"HIST-0017","category":"History","subcategory":"Investiture Controversy","difficulty":"medium","questionType":"multiple_choice","region":"Western Europe","timePeriod":"Medieval","tags":["Investiture Controversy","Gregory VII","Henry IV"],"question":"The Investiture Controversy centered on a conflict between Pope Gregory VII and which Holy Roman emperor?","options":["Frederick II","Otto I","Charles IV","Henry IV"],"correctAnswer":"Henry IV","explanation":"Gregory VII and Henry IV disputed whether secular rulers could appoint bishops, producing Henry's excommunication and journey to Canossa."},
  {"questionId":"HIST-0018","category":"History","subcategory":"Ottoman Institutions","difficulty":"medium","questionType":"multiple_choice","region":"Middle East","timePeriod":"Early Modern","tags":["devshirme","Janissaries","Ottoman Empire"],"question":"Which Ottoman system recruited Christian boys for conversion, education, and service to the sultan?","options":["Timar","Devshirme","Millet","Hajj"],"correctAnswer":"Devshirme","explanation":"The devshirme recruited boys who could be trained for administration or the elite Janissary infantry."},
  {"questionId":"HIST-0019","category":"History","subcategory":"Atlantic World","difficulty":"medium","questionType":"multiple_choice","region":"Global","timePeriod":"Early Modern","tags":["Columbian Exchange","Atlantic World","disease"],"question":"What term describes the transfer of crops, animals, diseases, and peoples between the Americas and Afro-Eurasia after 1492?","options":["Commercial Revolution","Columbian Exchange","Triangular Diplomacy","Great Divergence"],"correctAnswer":"Columbian Exchange","explanation":"The Columbian Exchange transformed diets, environments, populations, and economies on both sides of the Atlantic."},
  {"questionId":"HIST-0020","category":"History","subcategory":"Reformation Germany","difficulty":"medium","questionType":"multiple_choice","region":"Western Europe","timePeriod":"Early Modern","tags":["Peace of Augsburg","Reformation","Holy Roman Empire"],"question":"Which settlement allowed rulers in the Holy Roman Empire to choose between Lutheranism and Catholicism for their territories?","options":["Peace of Westphalia","Edict of Nantes","Peace of Augsburg","Concordat of Worms"],"correctAnswer":"Peace of Augsburg","explanation":"The Peace of Augsburg recognized Lutheranism and let each territorial ruler determine the territory's confession."},
  {"questionId":"HIST-0021","category":"History","subcategory":"Haitian Revolution","difficulty":"medium","questionType":"multiple_choice","region":"Latin America","timePeriod":"1700s","tags":["Toussaint Louverture","Haitian Revolution","Saint-Domingue"],"question":"Which formerly enslaved leader became a leading general and governor during the Haitian Revolution before being imprisoned by France?","options":["Jean-Jacques Dessalines","Henri Christophe","Toussaint Louverture","Alexandre Petion"],"correctAnswer":"Toussaint Louverture","explanation":"Toussaint Louverture became the revolution's leading commander and governed Saint-Domingue before Napoleon's forces arrested him."},
  {"questionId":"HIST-0022","category":"History","subcategory":"Congress of Vienna","difficulty":"medium","questionType":"multiple_choice","region":"Western Europe","timePeriod":"1800s","tags":["Metternich","Congress of Vienna","conservatism"],"question":"Which Austrian statesman was a principal architect of the conservative settlement created at the Congress of Vienna?","options":["Klemens von Metternich","Giuseppe Mazzini","Camillo di Cavour","Louis-Napoleon Bonaparte"],"correctAnswer":"Klemens von Metternich","explanation":"Metternich promoted a balance of power and cooperation among monarchies to contain revolution after Napoleon's defeat."},
  {"questionId":"HIST-0023","category":"History","subcategory":"U.S. Foreign Policy","difficulty":"medium","questionType":"multiple_choice","region":"Latin America","timePeriod":"1800s","tags":["Monroe Doctrine","Western Hemisphere","foreign policy"],"question":"The Monroe Doctrine warned European powers against further colonization in which part of the world?","options":["The Western Hemisphere","Southeast Asia","The Middle East","Sub-Saharan Africa"],"correctAnswer":"The Western Hemisphere","explanation":"The 1823 Monroe Doctrine opposed new European colonization and political intervention in the Americas."},
  {"questionId":"HIST-0024","category":"History","subcategory":"U.S. Women's Rights","difficulty":"medium","questionType":"multiple_choice","region":"United States","timePeriod":"1800s","tags":["Seneca Falls Convention","Declaration of Sentiments","women's rights"],"question":"Which document issued at the 1848 Seneca Falls Convention modeled its language on the Declaration of Independence?","options":["The Liberator","Declaration of Rights and Grievances","Declaration of Sentiments","The Revolution"],"correctAnswer":"Declaration of Sentiments","explanation":"The Declaration of Sentiments listed inequalities faced by women and called for women's suffrage."},
  {"questionId":"HIST-0025","category":"History","subcategory":"German Unification","difficulty":"medium","questionType":"multiple_choice","region":"Western Europe","timePeriod":"1800s","tags":["Otto von Bismarck","Realpolitik","German unification"],"question":"Which Prussian statesman used Realpolitik and a series of wars to help unify Germany?","options":["Otto von Bismarck","Friedrich Engels","Klemens von Metternich","Gustav Stresemann"],"correctAnswer":"Otto von Bismarck","explanation":"Bismarck directed Prussia through wars with Denmark, Austria, and France before the German Empire was proclaimed in 1871."},
  {"questionId":"HIST-0026","category":"History","subcategory":"Opium Wars","difficulty":"medium","questionType":"multiple_choice","region":"East Asia","timePeriod":"1800s","tags":["Treaty of Nanjing","Opium War","Qing China"],"question":"Which treaty ended the First Opium War and ceded Hong Kong Island to Britain?","options":["Treaty of Shimonoseki","Treaty of Nanjing","Treaty of Portsmouth","Treaty of Tianjin"],"correctAnswer":"Treaty of Nanjing","explanation":"The Treaty of Nanjing ended the First Opium War in 1842 and opened several Chinese ports to British trade."},
  {"questionId":"HIST-0027","category":"History","subcategory":"Indian Rebellion of 1857","difficulty":"medium","questionType":"multiple_choice","region":"South Asia","timePeriod":"1800s","tags":["Indian Rebellion","East India Company","British Raj"],"question":"The Indian Rebellion of 1857 began among soldiers serving which organization?","options":["British East India Company","Dutch East India Company","Indian National Congress","Royal African Company"],"correctAnswer":"British East India Company","explanation":"Indian soldiers in the East India Company's armies initiated the rebellion, after which Britain imposed direct imperial rule."},
  {"questionId":"HIST-0028","category":"History","subcategory":"European Imperialism","difficulty":"medium","questionType":"multiple_choice","region":"Sub-Saharan Africa","timePeriod":"1800s","tags":["Berlin Conference","Scramble for Africa","imperialism"],"question":"Which meeting established rules for European claims in Africa without including African representatives?","options":["Congress of Berlin","Berlin Conference","Algeciras Conference","Potsdam Conference"],"correctAnswer":"Berlin Conference","explanation":"The Berlin Conference of 1884-1885 formalized principles for European occupation and accelerated the partition of Africa."},
  {"questionId":"HIST-0029","category":"History","subcategory":"U.S. Foreign Policy","difficulty":"medium","questionType":"multiple_choice","region":"Latin America","timePeriod":"1900-1945","tags":["Roosevelt Corollary","Theodore Roosevelt","interventionism"],"question":"Which addition to the Monroe Doctrine asserted a United States right to intervene in Latin American countries?","options":["Open Door Policy","Good Neighbor Policy","Truman Doctrine","Roosevelt Corollary"],"correctAnswer":"Roosevelt Corollary","explanation":"The Roosevelt Corollary claimed that the United States could exercise international police power in the Western Hemisphere."},
  {"questionId":"HIST-0030","category":"History","subcategory":"Mexican Revolution","difficulty":"medium","questionType":"multiple_choice","region":"Latin America","timePeriod":"1900-1945","tags":["Francisco Madero","Plan of San Luis","Porfirio Diaz"],"question":"Which opponent of Porfirio Diaz issued the Plan of San Luis, calling for an uprising that began the Mexican Revolution?","options":["Emiliano Zapata","Francisco Madero","Venustiano Carranza","Alvaro Obregon"],"correctAnswer":"Francisco Madero","explanation":"Francisco Madero rejected the official 1910 election results and called for revolt against Porfirio Diaz's dictatorship."},
  {"questionId":"HIST-0031","category":"History","subcategory":"Russian Revolution","difficulty":"medium","questionType":"multiple_choice","region":"Eastern Europe","timePeriod":"1900-1945","tags":["April Theses","Lenin","Bolsheviks"],"question":"Which Bolshevik leader issued the April Theses after returning to Russia in 1917?","options":["Vladimir Lenin","Alexander Kerensky","Nicholas II","Lavrentiy Beria"],"correctAnswer":"Vladimir Lenin","explanation":"Lenin's April Theses rejected support for the provisional government and called for power to pass to the soviets."},
  {"questionId":"HIST-0032","category":"History","subcategory":"Chinese Civil War","difficulty":"medium","questionType":"multiple_choice","region":"East Asia","timePeriod":"1900-1945","tags":["Long March","Mao Zedong","Chinese Communists"],"question":"Which Chinese Communist leader strengthened his position within the party during the Long March?","options":["Sun Yat-sen","Chiang Kai-shek","Mao Zedong","Yuan Shikai"],"correctAnswer":"Mao Zedong","explanation":"The Long March preserved a core Communist force and helped Mao Zedong emerge as the movement's dominant leader."},
  {"questionId":"HIST-0033","category":"History","subcategory":"Cold War Europe","difficulty":"medium","questionType":"multiple_choice","region":"Western Europe","timePeriod":"1945-1991","tags":["Marshall Plan","European recovery","Cold War"],"question":"Which United States program provided economic aid to help rebuild Western Europe after World War II?","options":["Lend-Lease","Point Four Program","Marshall Plan","Alliance for Progress"],"correctAnswer":"Marshall Plan","explanation":"The Marshall Plan supplied billions of dollars to support European economic recovery and political stability."},
  {"questionId":"HIST-0034","category":"History","subcategory":"Asian-African Conference","difficulty":"medium","questionType":"multiple_choice","region":"Southeast Asia","timePeriod":"1945-1991","tags":["Bandung Conference","decolonization","nonalignment"],"question":"Which 1955 meeting in Indonesia brought Asian and African states together to discuss cooperation, colonialism, and Cold War neutrality?","options":["Bandung Conference","Yalta Conference","Geneva Summit","San Francisco Conference"],"correctAnswer":"Bandung Conference","explanation":"The Bandung Conference promoted Afro-Asian cooperation and helped build momentum for the Non-Aligned Movement."},
  {"questionId":"HIST-0035","category":"History","subcategory":"Roman Republic","difficulty":"hard","questionType":"multiple_choice","region":"Western Europe","timePeriod":"Ancient","tags":["Gracchi brothers","land reform","Roman Republic"],"question":"Which pair of Roman tribunes pursued controversial land reforms in the second century BCE?","options":["Gaius Marius and Lucius Sulla","Tiberius and Gaius Gracchus","Cato and Cicero","Pompey and Crassus"],"correctAnswer":"Tiberius and Gaius Gracchus","explanation":"The Gracchi brothers tried to redistribute public land and address inequality, but both were killed amid political violence."},
  {"questionId":"HIST-0036","category":"History","subcategory":"Byzantine Institutions","difficulty":"hard","questionType":"multiple_choice","region":"Eastern Europe","timePeriod":"Medieval","tags":["theme system","Byzantine Empire","military administration"],"question":"What name was given to the military-administrative provinces that became central to the defense of the Byzantine Empire?","options":["Themes","Satrapies","Vilayets","Nomoi"],"correctAnswer":"Themes","explanation":"The theme system organized Byzantine territory into military provinces whose commanders coordinated regional defense and administration."},
  {"questionId":"HIST-0037","category":"History","subcategory":"Songhai Empire","difficulty":"hard","questionType":"multiple_choice","region":"Sub-Saharan Africa","timePeriod":"Early Modern","tags":["Askia Muhammad","Songhai Empire","West Africa"],"question":"Which ruler overthrew Sunni Baru and established the Askia dynasty in the Songhai Empire?","options":["Askia Muhammad","Mansa Musa","Sundiata Keita","Idris Alooma"],"correctAnswer":"Askia Muhammad","explanation":"Askia Muhammad seized power in 1493 and expanded Songhai while strengthening its administration and Islamic connections."},
  {"questionId":"HIST-0038","category":"History","subcategory":"Safavid Empire","difficulty":"hard","questionType":"multiple_choice","region":"Middle East","timePeriod":"Early Modern","tags":["Shah Ismail I","Safavid Empire","Twelver Shiism"],"question":"Which ruler founded the Safavid Empire and made Twelver Shiism its official religion?","options":["Shah Abbas I","Nader Shah","Shah Ismail I","Tahmasp II"],"correctAnswer":"Shah Ismail I","explanation":"Shah Ismail I established Safavid rule in Iran in 1501 and made Twelver Shiism central to the state."},
  {"questionId":"HIST-0039","category":"History","subcategory":"Dutch Revolt","difficulty":"hard","questionType":"multiple_choice","region":"Western Europe","timePeriod":"Early Modern","tags":["Union of Utrecht","Dutch Revolt","Dutch Republic"],"question":"Which 1579 agreement united several northern Dutch provinces against Spanish rule?","options":["Union of Utrecht","Pacification of Ghent","Treaty of Munster","Compromise of Nobles"],"correctAnswer":"Union of Utrecht","explanation":"The Union of Utrecht strengthened the northern provinces and became a constitutional foundation of the Dutch Republic."},
  {"questionId":"HIST-0040","category":"History","subcategory":"War of the Spanish Succession","difficulty":"hard","questionType":"multiple_choice","region":"Western Europe","timePeriod":"1700s","tags":["Treaty of Utrecht","Spanish Succession","balance of power"],"question":"Which settlement helped end the War of the Spanish Succession and recognized Philip V as king of Spain?","options":["Treaty of Aix-la-Chapelle","Treaty of Utrecht","Treaty of Rastatt","Treaty of the Pyrenees"],"correctAnswer":"Treaty of Utrecht","explanation":"The Treaty of Utrecht preserved Philip V's throne while barring a union of the French and Spanish crowns."},
  {"questionId":"HIST-0041","category":"History","subcategory":"Ottoman Reform","difficulty":"hard","questionType":"multiple_choice","region":"Middle East","timePeriod":"1800s","tags":["Tanzimat","Ottoman Empire","modernization"],"question":"What name is given to the nineteenth-century Ottoman reform era launched with the Gulhane Edict?","options":["Tanzimat","Nahda","Nizam-i Cedid","Young Ottoman period"],"correctAnswer":"Tanzimat","explanation":"The Tanzimat reforms sought to centralize administration, modernize institutions, and standardize legal treatment for Ottoman subjects."},
  {"questionId":"HIST-0042","category":"History","subcategory":"Taiping Rebellion","difficulty":"hard","questionType":"multiple_choice","region":"East Asia","timePeriod":"1800s","tags":["Hong Xiuquan","Taiping Rebellion","Qing China"],"question":"Which religious leader founded the Taiping Heavenly Kingdom during a massive rebellion against the Qing dynasty?","options":["Zeng Guofan","Li Hongzhang","Hong Xiuquan","Kang Youwei"],"correctAnswer":"Hong Xiuquan","explanation":"Hong Xiuquan claimed a divine mission and led the Taiping movement before its defeat by Qing-aligned forces."},
  {"questionId":"HIST-0043","category":"History","subcategory":"Porfiriato","difficulty":"hard","questionType":"multiple_choice","region":"Latin America","timePeriod":"1800s","tags":["Porfirio Diaz","Porfiriato","Mexico"],"question":"The period known as the Porfiriato was dominated by which Mexican leader?","options":["Benito Juarez","Porfirio Diaz","Victoriano Huerta","Lazaro Cardenas"],"correctAnswer":"Porfirio Diaz","explanation":"Porfirio Diaz dominated Mexican politics from 1876 to 1911 while promoting investment and maintaining authoritarian rule."},
  {"questionId":"HIST-0044","category":"History","subcategory":"World War I Diplomacy","difficulty":"hard","questionType":"multiple_choice","region":"Middle East","timePeriod":"1900-1945","tags":["Sykes-Picot Agreement","Ottoman lands","imperial diplomacy"],"question":"Which secret wartime agreement outlined British and French spheres of influence in Ottoman Arab territories?","options":["Balfour Declaration","Hussein-McMahon Correspondence","Sykes-Picot Agreement","Treaty of Sevres"],"correctAnswer":"Sykes-Picot Agreement","explanation":"The 1916 Sykes-Picot Agreement anticipated a division of Ottoman Arab lands into British and French zones."},
  {"questionId":"HIST-0045","category":"History","subcategory":"Prague Spring","difficulty":"hard","questionType":"multiple_choice","region":"Eastern Europe","timePeriod":"1945-1991","tags":["Alexander Dubcek","Prague Spring","Czechoslovakia"],"question":"Which Czechoslovak leader promoted socialism with a human face during the Prague Spring?","options":["Vaclav Havel","Gustav Husak","Alexander Dubcek","Wladyslaw Gomulka"],"correctAnswer":"Alexander Dubcek","explanation":"Alexander Dubcek introduced reforms in 1968 before Warsaw Pact forces invaded Czechoslovakia and halted the Prague Spring."},
  {"questionId":"HIST-0046","category":"History","subcategory":"Ancient Egypt","difficulty":"easy","questionType":"fill_in_the_blank","region":"North Africa","timePeriod":"Ancient","tags":["Nile River","Egyptian agriculture","flooding"],"question":"Annual flooding of the ______ River deposited fertile soil that supported ancient Egyptian agriculture.","options":[],"correctAnswer":"Nile","explanation":"The Nile's inundation supplied water and silt to farmland, making intensive agriculture possible in an arid region."},
  {"questionId":"HIST-0047","category":"History","subcategory":"Italian Renaissance","difficulty":"easy","questionType":"fill_in_the_blank","region":"Western Europe","timePeriod":"Early Modern","tags":["Renaissance","Italy","city-states"],"question":"The Renaissance began in the prosperous city-states of ______.","options":[],"correctAnswer":"Italy","explanation":"Italian centers such as Florence, Venice, and Rome supported humanists and artists through trade wealth and patronage."},
  {"questionId":"HIST-0048","category":"History","subcategory":"Protestant Reformation","difficulty":"easy","questionType":"fill_in_the_blank","region":"Western Europe","timePeriod":"Early Modern","tags":["Martin Luther","Ninety-five Theses","Reformation"],"question":"In 1517, Martin ______ circulated the Ninety-five Theses challenging the sale of indulgences.","options":[],"correctAnswer":"Luther","explanation":"Martin Luther's criticism of indulgences helped begin the Protestant Reformation."},
  {"questionId":"HIST-0049","category":"History","subcategory":"U.S. Revolution","difficulty":"easy","questionType":"fill_in_the_blank","region":"North America","timePeriod":"1700s","tags":["Boston Tea Party","taxation","British Empire"],"question":"The 1773 protest in which colonists dumped East India Company tea into a harbor is known as the Boston Tea ______.","options":[],"correctAnswer":"Party","explanation":"The Boston Tea Party protested Parliament's tea policy and prompted Britain to impose the punitive Coercive Acts."},
  {"questionId":"HIST-0050","category":"History","subcategory":"U.S. Civil War","difficulty":"easy","questionType":"fill_in_the_blank","region":"United States","timePeriod":"1800s","tags":["Emancipation Proclamation","Abraham Lincoln","slavery"],"question":"President Lincoln's 1863 order declaring enslaved people free in areas under Confederate control was the ______ Proclamation.","options":[],"correctAnswer":"Emancipation","explanation":"The Emancipation Proclamation made the destruction of slavery an explicit Union war objective."},
  {"questionId":"HIST-0051","category":"History","subcategory":"Indian Independence","difficulty":"easy","questionType":"fill_in_the_blank","region":"South Asia","timePeriod":"1900-1945","tags":["Salt March","Mahatma Gandhi","civil disobedience"],"question":"Gandhi's 1930 protest against a British monopoly and tax is known as the ______ March.","options":[],"correctAnswer":"Salt","explanation":"Gandhi made salt in defiance of British law, inspiring a wider campaign of civil disobedience."},
  {"questionId":"HIST-0052","category":"History","subcategory":"Mongol Empire","difficulty":"medium","questionType":"fill_in_the_blank","region":"Central Asia","timePeriod":"Medieval","tags":["Pax Mongolica","Mongol Empire","Silk Roads"],"question":"The period of improved security and exchange across much of Mongol-controlled Eurasia is called the Pax ______.","options":[],"correctAnswer":"Mongolica","explanation":"The Pax Mongolica facilitated travel, commerce, and cultural exchange across the Mongol successor states."},
  {"questionId":"HIST-0053","category":"History","subcategory":"Reconquista","difficulty":"medium","questionType":"fill_in_the_blank","region":"Western Europe","timePeriod":"Early Modern","tags":["Granada","Reconquista","Iberian Peninsula"],"question":"The conquest of ______ by Ferdinand and Isabella in 1492 ended the last Muslim-ruled state on the Iberian Peninsula.","options":[],"correctAnswer":"Granada","explanation":"The surrender of Granada ended Nasrid rule and completed the territorial expansion commonly called the Reconquista."},
  {"questionId":"HIST-0054","category":"History","subcategory":"Tokugawa Japan","difficulty":"medium","questionType":"fill_in_the_blank","region":"East Asia","timePeriod":"Early Modern","tags":["Tokugawa shogunate","Japan","Edo period"],"question":"The military government established in Japan by Tokugawa Ieyasu was the Tokugawa ______.","options":[],"correctAnswer":"shogunate","explanation":"The Tokugawa shogunate governed Japan from 1603 to 1868 through a balance of shogunal and daimyo authority."},
  {"questionId":"HIST-0055","category":"History","subcategory":"Spanish Colonial America","difficulty":"medium","questionType":"fill_in_the_blank","region":"Latin America","timePeriod":"Early Modern","tags":["encomienda","Spanish Empire","forced labor"],"question":"The Spanish colonial institution that granted settlers claims to Indigenous labor and tribute was the ______ system.","options":[],"correctAnswer":"encomienda","explanation":"The encomienda placed Indigenous communities under Spanish grantees who demanded labor or tribute."},
  {"questionId":"HIST-0056","category":"History","subcategory":"Glorious Revolution","difficulty":"medium","questionType":"fill_in_the_blank","region":"Western Europe","timePeriod":"Early Modern","tags":["Glorious Revolution","James II","English monarchy"],"question":"The overthrow of James II in 1688 is commonly called the ______ Revolution.","options":[],"correctAnswer":"Glorious","explanation":"The Glorious Revolution replaced James II with William and Mary and strengthened Parliament's constitutional position."},
  {"questionId":"HIST-0057","category":"History","subcategory":"Industrial Revolution","difficulty":"medium","questionType":"fill_in_the_blank","region":"Western Europe","timePeriod":"1800s","tags":["Luddites","industrialization","labor protest"],"question":"English textile workers who attacked machinery during the early Industrial Revolution became known as ______.","options":[],"correctAnswer":"Luddites","explanation":"The Luddites protested production changes that threatened skilled work, wages, and established labor practices."},
  {"questionId":"HIST-0058","category":"History","subcategory":"Antebellum United States","difficulty":"medium","questionType":"fill_in_the_blank","region":"United States","timePeriod":"1800s","tags":["Fugitive Slave Act","Compromise of 1850","slavery"],"question":"The Compromise of 1850 included a strengthened ______ Slave Act requiring assistance in capturing people who escaped slavery.","options":[],"correctAnswer":"Fugitive","explanation":"The strengthened Fugitive Slave Act denied alleged fugitives key legal protections and intensified Northern opposition to slavery."},
  {"questionId":"HIST-0059","category":"History","subcategory":"Young Turk Revolution","difficulty":"medium","questionType":"fill_in_the_blank","region":"Middle East","timePeriod":"1900-1945","tags":["Young Turks","Ottoman constitution","Committee of Union and Progress"],"question":"The 1908 movement that forced Sultan Abdulhamid II to restore the Ottoman constitution was led by the ______ Turks.","options":[],"correctAnswer":"Young","explanation":"The Young Turk Revolution restored constitutional government and elevated the Committee of Union and Progress."},
  {"questionId":"HIST-0060","category":"History","subcategory":"Soviet Reform","difficulty":"medium","questionType":"fill_in_the_blank","region":"Eastern Europe","timePeriod":"1945-1991","tags":["perestroika","Mikhail Gorbachev","Soviet Union"],"question":"Mikhail Gorbachev's policy of economic restructuring was called ______.","options":[],"correctAnswer":"perestroika","explanation":"Perestroika attempted to reform the Soviet economy through limited decentralization and market-oriented measures."},
  {"questionId":"HIST-0061","category":"History","subcategory":"Byzantine Law","difficulty":"hard","questionType":"fill_in_the_blank","region":"Eastern Europe","timePeriod":"Medieval","tags":["Corpus Juris Civilis","Justinian I","Roman law"],"question":"The compilation of Roman law commissioned by Justinian I is known in Latin as the Corpus Juris ______.","options":[],"correctAnswer":"Civilis","explanation":"The Corpus Juris Civilis preserved Roman legal writings and influenced later civil-law traditions."},
  {"questionId":"HIST-0062","category":"History","subcategory":"Mamluk Sultanate","difficulty":"hard","questionType":"fill_in_the_blank","region":"Middle East","timePeriod":"Medieval","tags":["Battle of Ain Jalut","Mamluks","Mongols"],"question":"In 1260, Mamluk forces defeated a Mongol army at the Battle of Ain ______.","options":[],"correctAnswer":"Jalut","explanation":"The victory at Ain Jalut halted Mongol expansion toward Egypt and strengthened Mamluk power."},
  {"questionId":"HIST-0063","category":"History","subcategory":"German Confederation","difficulty":"hard","questionType":"fill_in_the_blank","region":"Western Europe","timePeriod":"1800s","tags":["Carlsbad Decrees","Metternich","German nationalism"],"question":"The 1819 measures that imposed censorship and surveillance on universities in the German Confederation were the ______ Decrees.","options":[],"correctAnswer":"Carlsbad","explanation":"The Carlsbad Decrees targeted liberal and nationalist activity as Metternich suppressed revolutionary movements."},
  {"questionId":"HIST-0064","category":"History","subcategory":"Late Qing Reform","difficulty":"hard","questionType":"fill_in_the_blank","region":"East Asia","timePeriod":"1800s","tags":["Self-Strengthening Movement","Qing China","modernization"],"question":"The Qing effort to adopt Western military technology while preserving traditional institutions was the Self-______ Movement.","options":[],"correctAnswer":"Strengthening","explanation":"The Self-Strengthening Movement created arsenals, shipyards, schools, and industries without fundamentally changing Qing politics."},
  {"questionId":"HIST-0065","category":"History","subcategory":"Postwar Economic Order","difficulty":"hard","questionType":"fill_in_the_blank","region":"Global","timePeriod":"1900-1945","tags":["Bretton Woods","IMF","World Bank"],"question":"The 1944 conference that designed a postwar monetary system met at Bretton ______.","options":[],"correctAnswer":"Woods","explanation":"The Bretton Woods Conference created the framework for the International Monetary Fund and what became the World Bank."},
  {"questionId":"HIST-0066","category":"History","subcategory":"Ancient Rome","difficulty":"easy","questionType":"true_false","region":"Western Europe","timePeriod":"Ancient","tags":["Roman Republic","Roman Empire","political history"],"question":"The Roman Republic existed before the Roman Empire.","options":["True","False"],"correctAnswer":true,"explanation":"The Roman Republic traditionally began in 509 BCE, while Augustus established the imperial system centuries later."},
  {"questionId":"HIST-0067","category":"History","subcategory":"Inca Empire","difficulty":"easy","questionType":"true_false","region":"Latin America","timePeriod":"Early Modern","tags":["Inca Empire","quipu","record keeping"],"question":"The Inca used knotted cords known as quipu to record information.","options":["True","False"],"correctAnswer":true,"explanation":"Quipu encoded numerical and administrative information through combinations of knots, colors, and cord placement."},
  {"questionId":"HIST-0068","category":"History","subcategory":"Napoleonic Wars","difficulty":"easy","questionType":"true_false","region":"Western Europe","timePeriod":"1800s","tags":["Waterloo","Napoleon Bonaparte","Hundred Days"],"question":"Napoleon Bonaparte's final defeat occurred at the Battle of Waterloo.","options":["True","False"],"correctAnswer":true,"explanation":"Napoleon's defeat at Waterloo in 1815 ended the Hundred Days and led to his second abdication."},
  {"questionId":"HIST-0069","category":"History","subcategory":"Mughal Empire","difficulty":"medium","questionType":"true_false","region":"South Asia","timePeriod":"Early Modern","tags":["Akbar","religious toleration","Mughal Empire"],"question":"Mughal emperor Akbar generally promoted religious toleration toward his non-Muslim subjects.","options":["True","False"],"correctAnswer":true,"explanation":"Akbar included non-Muslims in his administration, abolished the jizya tax, and sponsored interreligious dialogue."},
  {"questionId":"HIST-0070","category":"History","subcategory":"Imperial Russia","difficulty":"medium","questionType":"true_false","region":"Eastern Europe","timePeriod":"Early Modern","tags":["Peter the Great","Saint Petersburg","Russian Empire"],"question":"Peter the Great established Saint Petersburg and transferred Russia's capital there.","options":["True","False"],"correctAnswer":true,"explanation":"Peter founded Saint Petersburg on territory gained from Sweden and made it the imperial capital in 1712."},
  {"questionId":"HIST-0071","category":"History","subcategory":"Congress of Vienna","difficulty":"medium","questionType":"true_false","region":"Western Europe","timePeriod":"1800s","tags":["Congress of Vienna","League of Nations","diplomacy"],"question":"The Congress of Vienna created the League of Nations.","options":["True","False"],"correctAnswer":false,"explanation":"The Congress reorganized Europe after Napoleon, while the League of Nations was created after World War I."},
  {"questionId":"HIST-0072","category":"History","subcategory":"Great Migration","difficulty":"medium","questionType":"true_false","region":"United States","timePeriod":"1900-1945","tags":["Great Migration","African Americans","urbanization"],"question":"During the Great Migration, millions of African Americans moved from the rural South to cities in other parts of the United States.","options":["True","False"],"correctAnswer":true,"explanation":"African Americans moved primarily to Northern, Midwestern, and Western cities for jobs and relief from Jim Crow oppression."},
  {"questionId":"HIST-0073","category":"History","subcategory":"Age of Exploration","difficulty":"medium","questionType":"true_false","region":"Latin America","timePeriod":"Early Modern","tags":["Treaty of Tordesillas","Spain","Portugal"],"question":"The Treaty of Tordesillas attempted to divide newly claimed overseas lands between Spain and Portugal.","options":["True","False"],"correctAnswer":true,"explanation":"The 1494 treaty established a line intended to separate Spanish and Portuguese zones of expansion."},
  {"questionId":"HIST-0074","category":"History","subcategory":"Ottoman Institutions","difficulty":"hard","questionType":"true_false","region":"Middle East","timePeriod":"Early Modern","tags":["millet system","Ottoman Empire","religious communities"],"question":"The Ottoman millet system primarily organized certain subject communities according to religious affiliation.","options":["True","False"],"correctAnswer":true,"explanation":"Recognized religious communities administered some internal legal, educational, and charitable affairs under their own leaders."},
  {"questionId":"HIST-0075","category":"History","subcategory":"Hungarian Revolution of 1956","difficulty":"hard","questionType":"true_false","region":"Eastern Europe","timePeriod":"1945-1991","tags":["Hungarian Revolution","NATO","Soviet Union"],"question":"NATO sent military forces to defend the Hungarian Revolution of 1956 against Soviet intervention.","options":["True","False"],"correctAnswer":false,"explanation":"Western governments condemned the Soviet invasion but did not intervene militarily, and Soviet forces suppressed the revolution."},
  {"questionId":"HIST-0076","category":"History","subcategory":"Achaemenid Empire","difficulty":"easy","questionType":"short_answer","region":"Middle East","timePeriod":"Ancient","tags":["Cyrus the Great","Achaemenid Empire","Persia"],"question":"Who founded the Achaemenid Persian Empire after defeating the Median king Astyages?","options":[],"correctAnswer":"Cyrus the Great","explanation":"Cyrus the Great established the Achaemenid Empire and expanded it across much of the Middle East."},
  {"questionId":"HIST-0077","category":"History","subcategory":"Carolingian Empire","difficulty":"easy","questionType":"short_answer","region":"Western Europe","timePeriod":"Medieval","tags":["Charlemagne","Carolingian Empire","papacy"],"question":"Which Frankish ruler was crowned emperor by Pope Leo III on Christmas Day in 800?","options":[],"correctAnswer":"Charlemagne","explanation":"Charlemagne's coronation linked the Carolingian monarchy with the papacy and revived the imperial title in Western Europe."},
  {"questionId":"HIST-0078","category":"History","subcategory":"Hundred Years' War","difficulty":"easy","questionType":"short_answer","region":"Western Europe","timePeriod":"Medieval","tags":["Joan of Arc","Hundred Years' War","Orleans"],"question":"Which French heroine helped lift the English siege of Orleans during the Hundred Years' War?","options":[],"correctAnswer":"Joan of Arc","explanation":"Joan of Arc inspired French forces at Orleans and helped clear the way for Charles VII's coronation."},
  {"questionId":"HIST-0079","category":"History","subcategory":"Latin American Independence","difficulty":"easy","questionType":"short_answer","region":"Latin America","timePeriod":"1800s","tags":["Simon Bolivar","independence","South America"],"question":"Which leader known as the Liberator helped win independence for several northern South American countries?","options":[],"correctAnswer":"Simon Bolivar","explanation":"Simon Bolivar led campaigns that contributed to the independence of Venezuela, Colombia, Ecuador, Peru, and Bolivia."},
  {"questionId":"HIST-0080","category":"History","subcategory":"U.S. Women's Suffrage","difficulty":"easy","questionType":"short_answer","region":"United States","timePeriod":"1800s","tags":["Susan B. Anthony","women's suffrage","Nineteenth Amendment"],"question":"Which American suffragist worked closely with Elizabeth Cady Stanton and later appeared on a United States dollar coin?","options":[],"correctAnswer":"Susan B. Anthony","explanation":"Susan B. Anthony organized for women's voting rights for decades, although the Nineteenth Amendment came after her death."},
  {"questionId":"HIST-0081","category":"History","subcategory":"World War II Britain","difficulty":"easy","questionType":"short_answer","region":"Western Europe","timePeriod":"1900-1945","tags":["Winston Churchill","Britain","World War II"],"question":"Who became British prime minister in May 1940 and led the country during most of World War II?","options":[],"correctAnswer":"Winston Churchill","explanation":"Winston Churchill replaced Neville Chamberlain as Germany invaded Western Europe and became a central Allied leader."},
  {"questionId":"HIST-0082","category":"History","subcategory":"Indian Independence","difficulty":"easy","questionType":"short_answer","region":"South Asia","timePeriod":"1900-1945","tags":["Mahatma Gandhi","nonviolence","Indian independence"],"question":"Which Indian independence leader promoted nonviolent resistance through the principle of satyagraha?","options":[],"correctAnswer":"Mahatma Gandhi","explanation":"Mahatma Gandhi used satyagraha, mass protest, and civil disobedience to challenge British colonial rule."},
  {"questionId":"HIST-0083","category":"History","subcategory":"Peloponnesian War","difficulty":"medium","questionType":"short_answer","region":"Western Europe","timePeriod":"Ancient","tags":["Peloponnesian War","Athens","Sparta"],"question":"Which two leading Greek city-states fought against each other in the Peloponnesian War?","options":[],"correctAnswer":"Athens and Sparta","explanation":"Athens led the Delian League while Sparta led the Peloponnesian League, and Sparta ultimately prevailed."},
  {"questionId":"HIST-0084","category":"History","subcategory":"Mali Empire","difficulty":"medium","questionType":"short_answer","region":"Sub-Saharan Africa","timePeriod":"Medieval","tags":["Mansa Musa","Mali Empire","pilgrimage"],"question":"Which ruler of the Mali Empire became famous for his lavish pilgrimage to Mecca?","options":[],"correctAnswer":"Mansa Musa","explanation":"Mansa Musa's pilgrimage displayed Mali's wealth and strengthened its Islamic commercial and scholarly connections."},
  {"questionId":"HIST-0085","category":"History","subcategory":"Ming China","difficulty":"medium","questionType":"short_answer","region":"East Asia","timePeriod":"Early Modern","tags":["Zheng He","Ming dynasty","treasure voyages"],"question":"Which Ming admiral commanded seven major maritime expeditions across the Indian Ocean?","options":[],"correctAnswer":"Zheng He","explanation":"Zheng He led fleets that visited Southeast Asia, South Asia, Arabia, and East Africa during the early fifteenth century."},
  {"questionId":"HIST-0086","category":"History","subcategory":"Ottoman Empire","difficulty":"medium","questionType":"short_answer","region":"Middle East","timePeriod":"Early Modern","tags":["Suleiman the Magnificent","Ottoman Empire","law"],"question":"Which Ottoman sultan was known in Europe as the Magnificent and in his empire as the Lawgiver?","options":[],"correctAnswer":"Suleiman the Magnificent","explanation":"Suleiman expanded Ottoman territory and sponsored major legal, administrative, architectural, and cultural achievements."},
  {"questionId":"HIST-0087","category":"History","subcategory":"Enlightenment","difficulty":"medium","questionType":"short_answer","region":"Western Europe","timePeriod":"Early Modern","tags":["John Locke","natural rights","Enlightenment"],"question":"Which English philosopher wrote Two Treatises of Government and defended natural rights?","options":[],"correctAnswer":"John Locke","explanation":"John Locke argued that legitimate governments protect natural rights and derive authority from the consent of the governed."},
  {"questionId":"HIST-0088","category":"History","subcategory":"Zulu Kingdom","difficulty":"medium","questionType":"short_answer","region":"Sub-Saharan Africa","timePeriod":"1800s","tags":["Shaka","Zulu Kingdom","southern Africa"],"question":"Which early nineteenth-century ruler built the Zulu kingdom into a major power in southern Africa?","options":[],"correctAnswer":"Shaka","explanation":"Shaka expanded Zulu authority through military organization, political consolidation, and incorporation of neighboring communities."},
  {"questionId":"HIST-0089","category":"History","subcategory":"Latin American Independence","difficulty":"medium","questionType":"short_answer","region":"Latin America","timePeriod":"1800s","tags":["Jose de San Martin","independence","Argentina"],"question":"Which general crossed the Andes and helped liberate Argentina, Chile, and Peru from Spanish rule?","options":[],"correctAnswer":"Jose de San Martin","explanation":"Jose de San Martin organized the Army of the Andes and led campaigns that weakened Spanish authority in southern South America."},
  {"questionId":"HIST-0090","category":"History","subcategory":"Antebellum United States","difficulty":"medium","questionType":"short_answer","region":"United States","timePeriod":"1800s","tags":["Dred Scott","Supreme Court","slavery"],"question":"Which enslaved man was the plaintiff in an 1857 Supreme Court case that denied United States citizenship to African Americans?","options":[],"correctAnswer":"Dred Scott","explanation":"Dred Scott v. Sandford ruled against Scott and held that Congress could not prohibit slavery in federal territories."},
  {"questionId":"HIST-0091","category":"History","subcategory":"Chinese Revolution","difficulty":"medium","questionType":"short_answer","region":"East Asia","timePeriod":"1900-1945","tags":["Sun Yat-sen","1911 Revolution","Chinese nationalism"],"question":"Which revolutionary leader is often called the father of modern China and served as the first provisional president of the Republic of China?","options":[],"correctAnswer":"Sun Yat-sen","explanation":"Sun Yat-sen promoted nationalism, democracy, and people's livelihood and symbolized the revolution that overthrew the Qing."},
  {"questionId":"HIST-0092","category":"History","subcategory":"Nazi Germany","difficulty":"medium","questionType":"short_answer","region":"Western Europe","timePeriod":"1900-1945","tags":["Nuremberg Laws","Nazi Germany","antisemitism"],"question":"What name is given to the 1935 laws that stripped German Jews of citizenship and prohibited marriages with people classified as German?","options":[],"correctAnswer":"Nuremberg Laws","explanation":"The Nuremberg Laws embedded Nazi racial ideology in German law and intensified the systematic persecution of Jews."},
  {"questionId":"HIST-0093","category":"History","subcategory":"Cold War Strategy","difficulty":"medium","questionType":"short_answer","region":"Global","timePeriod":"1945-1991","tags":["George Kennan","containment","Long Telegram"],"question":"Which American diplomat wrote the Long Telegram and became closely associated with containing Soviet expansion?","options":[],"correctAnswer":"George Kennan","explanation":"George Kennan argued that sustained political and economic pressure could contain Soviet influence."},
  {"questionId":"HIST-0094","category":"History","subcategory":"Archaic Athens","difficulty":"hard","questionType":"short_answer","region":"Western Europe","timePeriod":"Ancient","tags":["Solon","Athens","debt slavery"],"question":"Which Athenian lawgiver introduced reforms that canceled many debts and ended debt slavery for Athenian citizens?","options":[],"correctAnswer":"Solon","explanation":"Solon's reforms reduced social tensions in archaic Athens and reorganized political participation according to wealth."},
  {"questionId":"HIST-0095","category":"History","subcategory":"Songhai Empire","difficulty":"hard","questionType":"short_answer","region":"Sub-Saharan Africa","timePeriod":"Medieval","tags":["Sunni Ali","Songhai Empire","West Africa"],"question":"Which fifteenth-century ruler expanded Songhai by capturing Timbuktu and Jenne?","options":[],"correctAnswer":"Sunni Ali","explanation":"Sunni Ali used cavalry and river forces to transform Songhai into the leading empire of the western Sudan."},
  {"questionId":"HIST-0096","category":"History","subcategory":"Safavid Empire","difficulty":"hard","questionType":"short_answer","region":"Middle East","timePeriod":"Early Modern","tags":["Shah Abbas I","Isfahan","Safavid Empire"],"question":"Which Safavid ruler moved his capital to Isfahan and presided over a major period of imperial revival?","options":[],"correctAnswer":"Shah Abbas I","explanation":"Shah Abbas I strengthened the army and government while developing Isfahan into a commercial and architectural center."},
  {"questionId":"HIST-0097","category":"History","subcategory":"Weimar Germany","difficulty":"hard","questionType":"short_answer","region":"Western Europe","timePeriod":"1900-1945","tags":["Gustav Stresemann","Locarno Treaties","Weimar Republic"],"question":"Which German foreign minister pursued reconciliation with France and helped negotiate the Locarno Treaties?","options":[],"correctAnswer":"Gustav Stresemann","explanation":"Gustav Stresemann improved Germany's international position and shared the 1926 Nobel Peace Prize with Aristide Briand."},
  {"questionId":"HIST-0098","category":"History","subcategory":"Indian Rebellion of 1857","difficulty":"hard","questionType":"short_answer","region":"South Asia","timePeriod":"1800s","tags":["Rani Lakshmibai","Jhansi","Indian Rebellion"],"question":"Which queen of Jhansi became a prominent resistance leader during the Indian Rebellion of 1857?","options":[],"correctAnswer":"Rani Lakshmibai","explanation":"Rani Lakshmibai led forces against British troops and became an enduring symbol of resistance to colonial rule."},
  {"questionId":"HIST-0099","category":"History","subcategory":"Algerian War","difficulty":"hard","questionType":"short_answer","region":"North Africa","timePeriod":"1945-1991","tags":["National Liberation Front","Algerian War","decolonization"],"question":"Which organization led the armed struggle against French rule during the Algerian War of Independence?","options":[],"correctAnswer":"National Liberation Front","explanation":"The National Liberation Front, or FLN, coordinated resistance that culminated in Algerian independence in 1962."},
  {"questionId":"HIST-0100","category":"History","subcategory":"Velvet Revolution","difficulty":"hard","questionType":"short_answer","region":"Eastern Europe","timePeriod":"1945-1991","tags":["Vaclav Havel","Velvet Revolution","Czechoslovakia"],"question":"Which dissident playwright became president of Czechoslovakia after the Velvet Revolution?","options":[],"correctAnswer":"Vaclav Havel","explanation":"Vaclav Havel helped lead the Civic Forum during the peaceful 1989 revolution and became president after communist rule collapsed."}
]
$history$::jsonb) as item(
    "questionId" text,
    category text,
    subcategory text,
    difficulty text,
    "questionType" text,
    region text,
    "timePeriod" text,
    tags text[],
    question text,
    options jsonb,
    "correctAnswer" jsonb,
    explanation text
  )
)
insert into public.questions (
  id, category, subcategory, difficulty, question_type, region, time_period,
  tags, question, options, correct_answer, accepted_answer, aliases,
  explanation, published
)
select
  "questionId", category, subcategory, difficulty, "questionType", region,
  "timePeriod", tags, question, options, "correctAnswer",
  case
    when jsonb_typeof("correctAnswer") = 'string' then "correctAnswer" #>> '{}'
    else "correctAnswer"::text
  end,
  case "questionId"
    when 'HIST-0083' then array['Sparta and Athens', 'Athens, Sparta']
    when 'HIST-0099' then array['FLN']
    when 'HIST-0091' then array['Sun Yatsen']
    when 'HIST-0089' then array['San Martin']
    when 'HIST-0016' then array['William the Conqueror']
    when 'HIST-0035' then array['Gracchi brothers', 'the Gracchi']
    when 'HIST-0065' then array['Bretton Woods']
    else '{}'::text[]
  end,
  explanation,
  true
from batch
on conflict (id) do update set
  category = excluded.category,
  subcategory = excluded.subcategory,
  difficulty = excluded.difficulty,
  question_type = excluded.question_type,
  region = excluded.region,
  time_period = excluded.time_period,
  tags = excluded.tags,
  question = excluded.question,
  options = excluded.options,
  correct_answer = excluded.correct_answer,
  accepted_answer = excluded.accepted_answer,
  aliases = excluded.aliases,
  explanation = excluded.explanation,
  published = excluded.published;

drop policy if exists "published question ids are readable" on public.questions;
revoke select on public.questions from authenticated;

create or replace function public.get_practice_questions(
  p_category text default null,
  p_count integer default 10
) returns jsonb
language sql volatile security definer set search_path = '' as $$
  with selected as (
    select q.*
    from public.questions q
    where q.published
      and q.question is not null
      and (p_category is null or q.category = p_category)
    order by random()
    limit greatest(1, least(coalesce(p_count, 10), 20))
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', id,
    'category', category,
    'subcategory', subcategory,
    'difficulty', difficulty,
    'questionType', question_type,
    'region', region,
    'timePeriod', time_period,
    'tags', to_jsonb(tags),
    'question', question,
    'options', options
  )), '[]'::jsonb)
  from selected;
$$;

create or replace function public.check_practice_answer(
  p_question_id text,
  p_submitted text
) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  quiz_question public.questions%rowtype;
  is_correct boolean;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if char_length(coalesce(p_submitted, '')) > 200 then raise exception 'Answer is too long'; end if;

  select * into quiz_question
  from public.questions
  where id = p_question_id and published and question is not null;
  if not found then raise exception 'Unknown question'; end if;

  is_correct := public.normalize_quiz_answer(p_submitted) = any(
    array(
      select public.normalize_quiz_answer(value)
      from unnest(array_prepend(quiz_question.accepted_answer, quiz_question.aliases)) value
    )
  );

  return jsonb_build_object(
    'correct', is_correct,
    'correctAnswer', quiz_question.correct_answer,
    'explanation', quiz_question.explanation
  );
end;
$$;

create or replace function public.complete_practice_session(
  p_session_type text,
  p_category text,
  p_answers jsonb,
  p_timezone text default 'UTC'
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  item jsonb;
  quiz_question public.questions%rowtype;
  session_id uuid := gen_random_uuid();
  answer_count integer;
  correct_count integer := 0;
  earned_xp integer;
  daily_bonus integer := 0;
  practice_day date;
  first_daily boolean := false;
  inserted_daily_count integer := 0;
  profile public.profiles%rowtype;
  submitted text;
  is_correct boolean;
begin
  if uid is null then raise exception 'Authentication required'; end if;
  if p_session_type not in ('daily', 'category') then raise exception 'Invalid session type'; end if;
  if jsonb_typeof(p_answers) <> 'array' then raise exception 'Answers must be an array'; end if;
  answer_count := jsonb_array_length(p_answers);
  if answer_count < 1 or answer_count > 20 then raise exception 'A session must contain 1-20 answers'; end if;
  if (select count(distinct value ->> 'questionId') from jsonb_array_elements(p_answers)) <> answer_count then
    raise exception 'A question can only be answered once per session';
  end if;

  begin
    practice_day := (now() at time zone p_timezone)::date;
  exception when invalid_parameter_value then
    raise exception 'Invalid timezone';
  end;

  for item in select value from jsonb_array_elements(p_answers)
  loop
    select * into quiz_question
    from public.questions
    where id = item ->> 'questionId' and published;
    if not found then raise exception 'Unknown question'; end if;
    submitted := left(coalesce(item ->> 'submitted', ''), 200);
    is_correct := public.normalize_quiz_answer(submitted) = any(
      array(
        select public.normalize_quiz_answer(value)
        from unnest(array_prepend(quiz_question.accepted_answer, quiz_question.aliases)) value
      )
    );
    if is_correct then correct_count := correct_count + 1; end if;
  end loop;

  earned_xp := correct_count * 10;
  insert into public.practice_sessions (
    id, user_id, session_type, category, question_count, correct_count, xp_earned
  ) values (
    session_id, uid, p_session_type, nullif(left(p_category, 50), ''),
    answer_count, correct_count, 0
  );

  for item in select value from jsonb_array_elements(p_answers)
  loop
    select * into quiz_question from public.questions where id = item ->> 'questionId';
    submitted := left(coalesce(item ->> 'submitted', ''), 200);
    is_correct := public.normalize_quiz_answer(submitted) = any(
      array(
        select public.normalize_quiz_answer(value)
        from unnest(array_prepend(quiz_question.accepted_answer, quiz_question.aliases)) value
      )
    );
    insert into public.session_answers (session_id, question_id, submitted_answer, is_correct)
    values (session_id, quiz_question.id, submitted, is_correct);
  end loop;

  if p_session_type = 'daily' then
    insert into public.daily_progress (user_id, practice_date, session_id)
    values (uid, practice_day, session_id)
    on conflict do nothing;
    get diagnostics inserted_daily_count = row_count;
    first_daily := inserted_daily_count = 1;
    if first_daily then
      daily_bonus := 20 + case when correct_count = answer_count then 25 else 0 end;
    end if;
  end if;

  earned_xp := earned_xp + daily_bonus;
  update public.practice_sessions set xp_earned = earned_xp where id = session_id;

  select * into profile from public.profiles where id = uid for update;
  if first_daily then
    profile.current_streak := case
      when profile.last_daily_completed_on = practice_day - 1 then profile.current_streak + 1
      else 1
    end;
    profile.longest_streak := greatest(profile.longest_streak, profile.current_streak);
    profile.last_daily_completed_on := practice_day;
  end if;

  update public.profiles set
    total_xp = total_xp + earned_xp,
    total_answered = total_answered + answer_count,
    total_correct = total_correct + correct_count,
    current_streak = profile.current_streak,
    longest_streak = profile.longest_streak,
    last_daily_completed_on = profile.last_daily_completed_on,
    updated_at = now()
  where id = uid returning * into profile;

  return jsonb_build_object(
    'sessionId', session_id,
    'xpEarned', earned_xp,
    'correctCount', correct_count,
    'profile', jsonb_build_object(
      'xp', profile.total_xp,
      'streak', profile.current_streak,
      'longest', profile.longest_streak,
      'answered', profile.total_answered,
      'correct', profile.total_correct,
      'done', profile.last_daily_completed_on
    )
  );
end;
$$;

revoke all on function public.get_practice_questions(text, integer) from public;
revoke all on function public.check_practice_answer(text, text) from public;
revoke all on function public.complete_practice_session(text, text, jsonb, text) from public;
grant execute on function public.get_practice_questions(text, integer) to authenticated;
grant execute on function public.check_practice_answer(text, text) to authenticated;
grant execute on function public.complete_practice_session(text, text, jsonb, text) to authenticated;
