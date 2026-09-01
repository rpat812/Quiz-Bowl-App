-- Add 500 deterministic history questions (five question angles for each of
-- 100 milestones). Keeping the source facts in SQL makes the batch auditable
-- and lets the migration remain compact without sacrificing unique prompts.

with source_facts(event_no, era, region, subcategory, event_name, event_year, place, figure, significance) as (
  values
    (1,'Ancient','Middle East','Ancient Mesopotamia','the unification of Upper and Lower Egypt','c. 3100 BCE','Egypt','Narmer','created an early unified Egyptian kingdom'),
    (2,'Ancient','Middle East','Ancient Mesopotamia','the creation of the Code of Hammurabi','c. 1754 BCE','Babylon','Hammurabi','recorded laws governing property, trade, and family life'),
    (3,'Ancient','Western Europe','Ancient Greece','the first recorded Olympic Games','776 BCE','Olympia','the ancient Greeks','began a major Panhellenic athletic and religious festival'),
    (4,'Ancient','Middle East','Achaemenid Persia','the founding of the Achaemenid Empire','c. 550 BCE','Persia','Cyrus the Great','created the largest empire the ancient world had yet seen'),
    (5,'Ancient','Western Europe','Ancient Greece','the Battle of Marathon','490 BCE','Marathon','Miltiades','ended the first Persian invasion of mainland Greece'),
    (6,'Ancient','Western Europe','Ancient Greece','the Battle of Thermopylae','480 BCE','Thermopylae','Leonidas I','became a lasting symbol of resistance to the Persian invasion'),
    (7,'Ancient','Western Europe','Ancient Greece','the beginning of the Peloponnesian War','431 BCE','Greece','Pericles','opened a prolonged struggle between Athens and Sparta'),
    (8,'Ancient','Western Europe','Macedonian Empire','the death of Alexander the Great','323 BCE','Babylon','Alexander the Great','triggered the division of his empire among successor kingdoms'),
    (9,'Ancient','South Asia','Mauryan Empire','the accession of Ashoka','c. 268 BCE','India','Ashoka','began a reign later associated with Buddhist patronage and moral governance'),
    (10,'Ancient','East Asia','Qin China','the unification of China under the Qin','221 BCE','China','Qin Shi Huang','established China''s first unified imperial dynasty'),
    (11,'Ancient','Western Europe','Roman Republic','the assassination of Julius Caesar','44 BCE','Rome','Julius Caesar','accelerated the crisis that ended the Roman Republic'),
    (12,'Ancient','Western Europe','Roman Empire','the Battle of Actium','31 BCE','Actium','Octavian','secured Octavian''s supremacy over the Roman world'),
    (13,'Ancient','Middle East','Early Christianity','the destruction of the Second Temple','70 CE','Jerusalem','Titus','transformed Jewish religious and political life under Roman rule'),
    (14,'Ancient','Western Europe','Roman Empire','the opening of the Colosseum','80 CE','Rome','Titus','created Rome''s most famous venue for public spectacles'),
    (15,'Ancient','East Asia','Han China','the invention of paper traditionally credited to Cai Lun','105 CE','China','Cai Lun','helped make written communication cheaper and more portable'),
    (16,'Ancient','Western Europe','Late Roman Empire','the Edict of Milan','313 CE','Milan','Constantine I','granted toleration to Christianity in the Roman Empire'),
    (17,'Ancient','Western Europe','Late Roman Empire','the founding of Constantinople as an imperial capital','330 CE','Constantinople','Constantine I','created an eastern capital that endured for more than a millennium'),
    (18,'Ancient','Western Europe','Late Roman Empire','the deposition of Romulus Augustulus','476 CE','Ravenna','Odoacer','traditionally marks the end of the Western Roman Empire'),
    (19,'Medieval','Western Europe','Byzantine Empire','the completion of Hagia Sophia','537 CE','Constantinople','Justinian I','produced a monumental center of Byzantine worship and architecture'),
    (20,'Medieval','Middle East','Early Islam','the Hijra','622 CE','Medina','Muhammad','established the Muslim community at Medina and begins the Islamic calendar'),
    (21,'Medieval','Western Europe','Carolingian Empire','the imperial coronation of Charlemagne','800 CE','Rome','Charlemagne','revived an imperial title in medieval Western Europe'),
    (22,'Medieval','Western Europe','Viking Age','the Viking raid on Lindisfarne','793 CE','Lindisfarne','Norse raiders','became a conventional marker for the beginning of the Viking Age'),
    (23,'Medieval','Western Europe','Norman England','the Battle of Hastings','1066 CE','Hastings','William the Conqueror','established Norman rule in England'),
    (24,'Medieval','Western Europe','Crusades','the capture of Jerusalem during the First Crusade','1099 CE','Jerusalem','the First Crusaders','created Latin Christian states in the eastern Mediterranean'),
    (25,'Medieval','East Asia','Song China','the first known use of movable type printing','c. 1040 CE','China','Bi Sheng','introduced reusable type for printing texts'),
    (26,'Medieval','Central Asia','Mongol Empire','the proclamation of Genghis Khan','1206 CE','Mongolia','Temujin','united Mongol groups under a ruler called Genghis Khan'),
    (27,'Medieval','Western Europe','Medieval England','the sealing of Magna Carta','1215 CE','Runnymede','King John','placed written limits on English royal authority'),
    (28,'Medieval','West Africa','Mali Empire','Mansa Musa''s pilgrimage to Mecca','1324 CE','Mecca','Mansa Musa','displayed Mali''s wealth and strengthened its Islamic connections'),
    (29,'Medieval','Global','Black Death','the arrival of the Black Death in Europe','1347 CE','Europe','Yersinia pestis','began a pandemic that killed a large share of Europe''s population'),
    (30,'Medieval','Western Europe','Hundred Years War','the relief of the siege of Orleans','1429 CE','Orleans','Joan of Arc','revived French fortunes during the Hundred Years'' War'),
    (31,'Early Modern','Western Europe','Renaissance','the completion of Gutenberg''s Bible','c. 1455 CE','Mainz','Johannes Gutenberg','demonstrated large-scale European printing with movable metal type'),
    (32,'Early Modern','Middle East','Ottoman Empire','the Ottoman conquest of Constantinople','1453 CE','Constantinople','Mehmed II','ended the Byzantine Empire and made the city an Ottoman capital'),
    (33,'Early Modern','Western Europe','Age of Exploration','Columbus''s first Atlantic voyage','1492 CE','the Caribbean','Christopher Columbus','initiated sustained contact between Europe and the Americas'),
    (34,'Early Modern','Western Europe','Reformation','the publication of the Ninety-five Theses','1517 CE','Wittenberg','Martin Luther','helped launch the Protestant Reformation'),
    (35,'Early Modern','Global','Circumnavigation','the completion of the first circumnavigation','1522 CE','Sanlucar de Barrameda','Juan Sebastian Elcano','demonstrated that a ship could sail around the globe'),
    (36,'Early Modern','South Asia','Mughal Empire','the First Battle of Panipat','1526 CE','Panipat','Babur','established Mughal power in northern India'),
    (37,'Early Modern','Western Europe','English Reformation','the Act of Supremacy','1534 CE','England','Henry VIII','made the English monarch supreme head of the Church of England'),
    (38,'Early Modern','East Asia','Japanese Unification','the Battle of Sekigahara','1600 CE','Sekigahara','Tokugawa Ieyasu','secured Tokugawa dominance over Japan'),
    (39,'Early Modern','North America','Colonial America','the founding of Jamestown','1607 CE','Virginia','the Virginia Company','created the first permanent English settlement in North America'),
    (40,'Early Modern','Western Europe','Scientific Revolution','the publication of the Principia','1687 CE','London','Isaac Newton','unified terrestrial and celestial motion through laws of mechanics and gravity'),
    (41,'1700s','Western Europe','Enlightenment','the publication of The Spirit of the Laws','1748 CE','Geneva','Montesquieu','popularized the political principle of separated powers'),
    (42,'1700s','North America','American Revolution','the Declaration of Independence','1776 CE','Philadelphia','Thomas Jefferson','announced the American colonies'' separation from Britain'),
    (43,'1700s','North America','United States Constitution','the signing of the United States Constitution','1787 CE','Philadelphia','James Madison','created the framework of the United States federal government'),
    (44,'1700s','Western Europe','French Revolution','the storming of the Bastille','1789 CE','Paris','Parisian revolutionaries','became a symbol of the French Revolution''s attack on royal authority'),
    (45,'1700s','Latin America','Haitian Revolution','the beginning of the Haitian Revolution','1791 CE','Saint-Domingue','enslaved revolutionaries','launched the only successful large-scale slave revolution in modern history'),
    (46,'1800s','Western Europe','Napoleonic Wars','the Battle of Waterloo','1815 CE','Waterloo','the Duke of Wellington','ended Napoleon''s final return to power'),
    (47,'1800s','Latin America','Latin American Independence','the Battle of Boyaca','1819 CE','New Granada','Simon Bolivar','secured a decisive victory for independence in northern South America'),
    (48,'1800s','North America','U.S. Foreign Policy','the announcement of the Monroe Doctrine','1823 CE','Washington, D.C.','James Monroe','warned European powers against new intervention in the Americas'),
    (49,'1800s','Western Europe','Industrial Revolution','the opening of the Liverpool and Manchester Railway','1830 CE','England','George Stephenson','demonstrated the commercial potential of intercity steam railways'),
    (50,'1800s','North America','U.S. Abolitionism','the publication of Frederick Douglass''s first autobiography','1845 CE','Boston','Frederick Douglass','gave a powerful firsthand indictment of American slavery'),
    (51,'1800s','Western Europe','European Revolutions','the Revolutions of 1848','1848 CE','Europe','liberal and nationalist revolutionaries','challenged conservative governments across much of Europe'),
    (52,'1800s','East Asia','Meiji Japan','the Meiji Restoration','1868 CE','Japan','Emperor Meiji','restored imperial rule and accelerated Japanese modernization'),
    (53,'1800s','North America','U.S. Civil War','the Battle of Gettysburg','1863 CE','Pennsylvania','George G. Meade','halted Robert E. Lee''s second invasion of the North'),
    (54,'1800s','Western Europe','German Unification','the proclamation of the German Empire','1871 CE','Versailles','Otto von Bismarck','completed the unification of most German states under Prussian leadership'),
    (55,'1800s','Sub-Saharan Africa','European Imperialism','the opening of the Berlin Conference','1884 CE','Berlin','Otto von Bismarck','set rules that accelerated European partition of Africa'),
    (56,'1800s','South Asia','Indian Nationalism','the founding of the Indian National Congress','1885 CE','Bombay','Allan Octavian Hume','created a major organization of the Indian independence movement'),
    (57,'1800s','East Asia','Sino-Japanese War','the Treaty of Shimonoseki','1895 CE','Shimonoseki','Ito Hirobumi','ended the First Sino-Japanese War and confirmed Japan''s regional rise'),
    (58,'1900-1945','East Asia','Chinese Revolution','the Xinhai Revolution','1911 CE','China','Sun Yat-sen','overthrew the Qing dynasty and led to a Chinese republic'),
    (59,'1900-1945','Global','World War I','the assassination of Archduke Franz Ferdinand','1914 CE','Sarajevo','Gavrilo Princip','triggered the diplomatic crisis that led to World War I'),
    (60,'1900-1945','Eastern Europe','Russian Revolution','the October Revolution','1917 CE','Petrograd','Vladimir Lenin','brought the Bolsheviks to power in Russia'),
    (61,'1900-1945','Western Europe','World War I','the Armistice of Compiegne','1918 CE','Compiegne','Ferdinand Foch','ended fighting on the Western Front in World War I'),
    (62,'1900-1945','Western Europe','Postwar Diplomacy','the signing of the Treaty of Versailles','1919 CE','Versailles','the Allied powers','formally ended the state of war between Germany and the Allies'),
    (63,'1900-1945','South Asia','Indian Independence','the Salt March','1930 CE','Dandi','Mahatma Gandhi','mobilized nonviolent resistance against British colonial rule'),
    (64,'1900-1945','Western Europe','Nazi Germany','the adoption of the Nuremberg Laws','1935 CE','Nuremberg','the Nazi regime','stripped German Jews of citizenship and imposed racial restrictions'),
    (65,'1900-1945','Western Europe','World War II','the German invasion of Poland','1939 CE','Poland','Adolf Hitler','began World War II in Europe'),
    (66,'1900-1945','North America','World War II','the attack on Pearl Harbor','1941 CE','Hawaii','the Imperial Japanese Navy','brought the United States into World War II'),
    (67,'1900-1945','Western Europe','World War II','the D-Day landings','1944 CE','Normandy','Dwight D. Eisenhower','opened a major Allied front in Western Europe'),
    (68,'1900-1945','Global','United Nations','the signing of the United Nations Charter','1945 CE','San Francisco','delegates from fifty nations','established the foundation of the United Nations'),
    (69,'1945-1991','South Asia','Indian Independence','the independence of India','1947 CE','New Delhi','Jawaharlal Nehru','ended British colonial rule over most of the Indian subcontinent'),
    (70,'1945-1991','Middle East','Modern Israel','the declaration of the State of Israel','1948 CE','Tel Aviv','David Ben-Gurion','established the modern State of Israel'),
    (71,'1945-1991','East Asia','Chinese Revolution','the proclamation of the People''s Republic of China','1949 CE','Beijing','Mao Zedong','established Communist rule in mainland China'),
    (72,'1945-1991','Western Europe','European Integration','the Treaty of Rome','1957 CE','Rome','the six founding EEC states','created the European Economic Community'),
    (73,'1945-1991','Sub-Saharan Africa','African Independence','the independence of Ghana','1957 CE','Accra','Kwame Nkrumah','made Ghana the first sub-Saharan African colony to gain independence after World War II'),
    (74,'1945-1991','Latin America','Cuban Revolution','the victory of the Cuban Revolution','1959 CE','Havana','Fidel Castro','overthrew Fulgencio Batista and transformed Cuban politics'),
    (75,'1945-1991','North America','U.S. Civil Rights','the March on Washington','1963 CE','Washington, D.C.','Martin Luther King Jr.','built support for federal civil-rights legislation'),
    (76,'1945-1991','Sub-Saharan Africa','South African Apartheid','the Rivonia Trial sentencing','1964 CE','Pretoria','Nelson Mandela','imprisoned leading opponents of South African apartheid'),
    (77,'1945-1991','East Asia','Vietnam War','the Tet Offensive','1968 CE','South Vietnam','the Viet Cong and North Vietnamese forces','undermined American confidence in the Vietnam War'),
    (78,'1945-1991','North America','Space Race','the Apollo 11 Moon landing','1969 CE','the Moon','Neil Armstrong','placed humans on the Moon for the first time'),
    (79,'1945-1991','East Asia','Cold War China','Richard Nixon''s visit to China','1972 CE','Beijing','Richard Nixon','opened a new phase in relations between the United States and China'),
    (80,'1945-1991','Middle East','Egyptian-Israeli Relations','the Camp David Accords','1978 CE','Camp David','Anwar Sadat and Menachem Begin','created a framework for peace between Egypt and Israel'),
    (81,'1945-1991','Middle East','Iranian Revolution','the Iranian Revolution','1979 CE','Tehran','Ruhollah Khomeini','replaced Iran''s monarchy with an Islamic republic'),
    (82,'1945-1991','Eastern Europe','Cold War Poland','the founding of Solidarity','1980 CE','Gdansk','Lech Walesa','created the Soviet bloc''s first independent trade union'),
    (83,'1945-1991','Western Europe','Cold War Germany','the opening of the Berlin Wall','1989 CE','Berlin','East German citizens','symbolized the collapse of communist rule in Eastern Europe'),
    (84,'1945-1991','Global','Cold War','the dissolution of the Soviet Union','1991 CE','Moscow','Mikhail Gorbachev','ended the Soviet state and the central geopolitical conflict of the Cold War'),
    (85,'Post-1991','Sub-Saharan Africa','South African Apartheid','South Africa''s first fully democratic national election','1994 CE','South Africa','Nelson Mandela','ended white-minority political rule and elected Mandela president'),
    (86,'Post-1991','Western Europe','European Integration','the introduction of euro banknotes and coins','2002 CE','the eurozone','the European Central Bank','put a shared physical currency into circulation across much of Europe'),
    (87,'Post-1991','Global','International Justice','the establishment of the International Criminal Court','2002 CE','The Hague','the Rome Statute member states','created a permanent court for genocide, crimes against humanity, and war crimes'),
    (88,'Ancient','East Asia','Han China','Zhang Qian''s return from Central Asia','126 BCE','Chang''an','Zhang Qian','expanded Han knowledge of Central Asia and encouraged Silk Road exchange'),
    (89,'Ancient','North Africa','Carthaginian Wars','the Battle of Zama','202 BCE','Zama','Scipio Africanus','ended the Second Punic War in Rome''s favor'),
    (90,'Medieval','East Asia','Mongol China','the founding of the Yuan dynasty','1271 CE','China','Kublai Khan','established a Mongol-ruled dynasty over China'),
    (91,'Medieval','Western Europe','Reconquista','the conquest of Granada','1492 CE','Granada','Isabella I and Ferdinand II','ended the last Muslim-ruled kingdom in Iberia'),
    (92,'Early Modern','Latin America','Spanish Conquest','the fall of Tenochtitlan','1521 CE','Tenochtitlan','Hernan Cortes','ended the Aztec Empire and established Spanish dominance in central Mexico'),
    (93,'Early Modern','South America','Spanish Conquest','the capture of Atahualpa','1532 CE','Cajamarca','Francisco Pizarro','enabled Spanish conquest of the Inca Empire'),
    (94,'Early Modern','Western Europe','Thirty Years War','the Peace of Westphalia','1648 CE','Westphalia','European diplomats','ended the Thirty Years'' War and reshaped European diplomacy'),
    (95,'1700s','Eastern Europe','Russian Empire','the founding of Saint Petersburg','1703 CE','Saint Petersburg','Peter the Great','created a new Russian port and future imperial capital'),
    (96,'1700s','South Asia','British India','the Battle of Plassey','1757 CE','Plassey','Robert Clive','established decisive British East India Company influence in Bengal'),
    (97,'1800s','East Asia','Opium Wars','the Treaty of Nanjing','1842 CE','Nanjing','Qiying and Henry Pottinger','ended the First Opium War and ceded Hong Kong Island to Britain'),
    (98,'1800s','East Asia','Japanese Foreign Relations','the Convention of Kanagawa','1854 CE','Kanagawa','Matthew Perry','opened Japanese ports to American vessels and weakened Tokugawa isolation'),
    (99,'1900-1945','Middle East','Modern Turkey','the proclamation of the Republic of Turkey','1923 CE','Ankara','Mustafa Kemal Ataturk','created a republic from the core of the former Ottoman Empire'),
    (100,'1945-1991','Southeast Asia','Southeast Asian Independence','the proclamation of Indonesian independence','1945 CE','Jakarta','Sukarno','declared Indonesia independent from Dutch colonial rule')
), angles(angle_no, prompt_template, answer_field) as (
  values
    (1, 'When did %s occur?', 'year'),
    (2, 'Where did %s occur?', 'place'),
    (3, 'Who is most closely associated with %s?', 'figure'),
    (4, 'Which historical development %s?', 'significance'),
    (5, 'Identify the event: In %s, %s was associated with a development that %s.', 'event')
), generated as (
  select
    'HIST-' || lpad((100 + (f.event_no - 1) * 5 + a.angle_no)::text, 4, '0') as id,
    f.*,
    a.angle_no,
    case a.angle_no
      when 1 then format(a.prompt_template, f.event_name)
      when 2 then format(a.prompt_template, f.event_name)
      when 3 then format(a.prompt_template, f.event_name)
      when 4 then format(a.prompt_template, f.significance)
      else format(a.prompt_template, f.event_year, f.figure, f.significance)
    end as question,
    case a.answer_field
      when 'year' then f.event_year
      when 'place' then f.place
      when 'figure' then f.figure
      when 'significance' then f.event_name
      else f.event_name
    end as answer
  from source_facts f cross join angles a
)
insert into public.questions (
  id, accepted_answer, aliases, published, category, subcategory, difficulty,
  question_type, region, time_period, tags, question, options,
  correct_answer, explanation, content_status
)
select
  id,
  answer,
  '{}',
  true,
  'History',
  subcategory,
  case when event_no <= 34 then 'easy' when event_no <= 76 then 'medium' else 'hard' end,
  'short_answer',
  region,
  era,
  array[event_name, figure, place],
  question,
  '[]'::jsonb,
  to_jsonb(answer),
  initcap(event_name) || ' occurred in ' || event_year || ' at or in ' || place ||
    ', is associated with ' || figure || ', and ' || significance || '.',
  'published'
from generated
on conflict (id) do update set
  accepted_answer = excluded.accepted_answer,
  aliases = excluded.aliases,
  published = excluded.published,
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
  explanation = excluded.explanation,
  content_status = excluded.content_status,
  updated_at = now();

do $$
begin
  if (select count(*) from public.questions where id between 'HIST-0101' and 'HIST-0600') <> 500 then
    raise exception 'Expected exactly 500 questions in history batch 2';
  end if;
end;
$$;
