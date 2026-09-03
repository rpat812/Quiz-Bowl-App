-- Add 500 science questions: ten independently worded angles for each of
-- 50 foundational topics across biology, chemistry, physics, Earth science,
-- and astronomy. Source facts remain visible here for editorial review.

with source_facts(
  topic_no, subcategory, difficulty, concept, key_term, mechanism, result, application
) as (
  values
    (1,'Cell Biology','easy','cell theory','the cell','organisms consist of one or more cells','new cells arise from existing cells','interpreting tissue structure'),
    (2,'Cell Biology','easy','cellular respiration','mitochondria','cells oxidize nutrients to transfer energy into ATP','usable chemical energy becomes available to cells','comparing metabolic activity'),
    (3,'Cell Biology','medium','osmosis','a selectively permeable membrane','water moves toward the side with greater effective solute concentration','cells gain or lose water','predicting cell behavior in saline solutions'),
    (4,'Molecular Biology','medium','DNA replication','DNA polymerase','each parental strand templates a complementary strand','two nearly identical DNA molecules are produced','copying genetic information before cell division'),
    (5,'Molecular Biology','medium','protein synthesis','ribosomes','messenger RNA codons direct the order of amino acids','a polypeptide is assembled','explaining how genes influence traits'),
    (6,'Genetics','easy','Mendelian inheritance','alleles','paired hereditary variants segregate during gamete formation','offspring receive one allele from each parent','predicting simple genetic crosses'),
    (7,'Genetics','hard','genetic recombination','crossing over','homologous chromosomes exchange corresponding DNA during meiosis','new combinations of alleles enter gametes','explaining variation among siblings'),
    (8,'Evolution','easy','natural selection','heritable variation','individuals with advantageous inherited traits leave more offspring','adaptation becomes more common across generations','explaining antibiotic resistance'),
    (9,'Ecology','medium','ecological succession','pioneer species','communities change as organisms modify available conditions','one community is gradually replaced by another','tracking ecosystem recovery after disturbance'),
    (10,'Human Physiology','medium','homeostasis','negative feedback','a deviation triggers responses that oppose the initial change','internal conditions remain within functional ranges','regulating body temperature'),
    (11,'General Chemistry','easy','conservation of mass','atoms','chemical reactions rearrange matter without creating or destroying atoms','reactant and product mass are equal in a closed system','balancing chemical equations'),
    (12,'Atomic Structure','easy','atomic number','protons','the number of nuclear protons defines an element','each element has a unique identity','organizing the periodic table'),
    (13,'Chemical Bonding','medium','ionic bonding','oppositely charged ions','electron transfer creates particles held by electrostatic attraction','a neutral ionic compound forms','explaining salts and crystal lattices'),
    (14,'Chemical Bonding','medium','covalent bonding','shared electron pairs','atoms share valence electrons','molecules or network solids form','predicting molecular structures'),
    (15,'Thermochemistry','medium','activation energy','the transition state','reactants must overcome an energy barrier before rearranging','only sufficiently energetic collisions react','explaining how catalysts speed reactions'),
    (16,'Equilibrium','hard','Le Chatelier''s principle','dynamic equilibrium','an equilibrium system shifts to oppose an imposed change','a new equilibrium composition is established','predicting effects of pressure or concentration changes'),
    (17,'Acids and Bases','easy','pH','hydrogen ion concentration','a logarithmic scale measures acidity and basicity','lower values correspond to greater acidity','monitoring water and soil chemistry'),
    (18,'Oxidation-Reduction','medium','redox reactions','electrons','oxidation transfers electrons to a species undergoing reduction','oxidation states change together','operating batteries'),
    (19,'Organic Chemistry','medium','functional groups','specific atom arrangements','recurring groups govern characteristic molecular reactions','compounds with different skeletons show related reactivity','classifying organic compounds'),
    (20,'Gas Laws','medium','the ideal gas law','pressure volume temperature and amount','the macroscopic variables of an ideal gas are mathematically related','changing one state variable constrains the others','predicting gas behavior'),
    (21,'Mechanics','easy','Newton''s second law','net force','acceleration equals net force divided by mass','unbalanced force changes velocity','predicting an object''s acceleration'),
    (22,'Mechanics','medium','conservation of momentum','total momentum','internal forces exchange momentum without changing an isolated system''s total','momentum before and after interaction is equal','analyzing collisions'),
    (23,'Energy','easy','conservation of energy','total energy','energy changes form or transfers while the total in a closed system remains constant','energy is accounted for rather than consumed','analyzing machines and motion'),
    (24,'Waves','medium','wave interference','superposition','overlapping disturbances add algebraically','constructive or destructive patterns appear','understanding noise-canceling headphones'),
    (25,'Optics','medium','refraction','wave speed','light changes speed and direction at a boundary between media','a ray bends unless it enters normally','designing lenses'),
    (26,'Electricity','easy','Ohm''s law','resistance','current equals voltage divided by resistance for an ohmic conductor','current responds predictably to applied voltage','designing simple circuits'),
    (27,'Electromagnetism','hard','electromagnetic induction','changing magnetic flux','a changing magnetic environment produces an electromotive force','current can be generated without direct contact','operating generators and transformers'),
    (28,'Thermodynamics','medium','the second law of thermodynamics','entropy','spontaneous processes increase total entropy in an isolated system','energy becomes less available for useful work','setting efficiency limits on heat engines'),
    (29,'Modern Physics','hard','the photoelectric effect','photons','electrons are emitted only when incident light exceeds a threshold frequency','light energy is transferred in discrete packets','supporting the quantum model of light'),
    (30,'Nuclear Physics','medium','radioactive decay','unstable nuclei','nuclei transform spontaneously with a characteristic probability','radiation and daughter nuclei are produced','radiometric dating'),
    (31,'Geology','easy','plate tectonics','lithospheric plates','rigid plates move over the weaker asthenosphere','continents shift and plate boundaries generate geologic activity','explaining global earthquake patterns'),
    (32,'Geology','medium','the rock cycle','igneous sedimentary and metamorphic rock','melting cooling weathering burial and heating transform rock materials','rock changes among major types over geologic time','interpreting landscape history'),
    (33,'Geology','medium','radiometric dating','radioactive isotopes','known decay rates relate parent and daughter isotope proportions to elapsed time','an absolute age estimate is calculated','dating ancient rocks'),
    (34,'Meteorology','easy','the water cycle','solar energy and gravity','evaporation condensation precipitation and runoff circulate water','water moves among atmosphere land ocean and organisms','understanding weather and freshwater supply'),
    (35,'Meteorology','medium','the Coriolis effect','Earth''s rotation','motion over a rotating planet appears deflected relative to its surface','large-scale winds and currents curve','explaining atmospheric circulation'),
    (36,'Climate Science','medium','the greenhouse effect','infrared-absorbing gases','the atmosphere absorbs and re-emits outgoing infrared radiation','Earth''s surface is warmer than it would be without these gases','understanding climate change'),
    (37,'Oceanography','medium','thermohaline circulation','density differences','temperature and salinity differences drive deep-ocean water movement','heat and dissolved substances circulate globally','studying long-term climate patterns'),
    (38,'Seismology','hard','seismic wave analysis','P waves and S waves','different waves travel differently through Earth materials','travel times reveal internal boundaries and properties','inferring Earth''s layered interior'),
    (39,'Earth History','medium','fossil succession','index fossils','recognizable fossil assemblages occur in a consistent chronological order','separated rock layers can be correlated by relative age','reconstructing geologic history'),
    (40,'Environmental Science','easy','the carbon cycle','carbon reservoirs','photosynthesis respiration decomposition combustion and exchange move carbon','carbon circulates among living things rocks oceans and atmosphere','tracking human effects on climate'),
    (41,'Solar System','easy','heliocentrism','the Sun','planets including Earth orbit a central star','apparent planetary motions can be modeled coherently','describing the organization of the solar system'),
    (42,'Stellar Astronomy','medium','stellar fusion','hydrogen nuclei','light nuclei combine under immense temperature and pressure','mass converts to energy while heavier nuclei form','explaining how main-sequence stars shine'),
    (43,'Stellar Astronomy','medium','the Hertzsprung-Russell diagram','luminosity and surface temperature','stars are plotted by intrinsic brightness against temperature','stellar groups and evolutionary stages become visible','classifying stars'),
    (44,'Cosmology','medium','cosmic expansion','galaxy redshift','distant galaxies generally recede faster as their distance increases','the scale of space grows over time','supporting the Big Bang model'),
    (45,'Cosmology','hard','cosmic microwave background','relic microwave radiation','early-universe radiation cooled as space expanded','a nearly uniform background now fills the sky','testing models of the early universe'),
    (46,'Galaxies','medium','dark matter','gravitational effects','observed motions and lensing require more gravitating mass than visible matter supplies','galaxies and clusters behave as if surrounded by unseen mass','modeling galaxy rotation'),
    (47,'Exoplanets','medium','the transit method','periodic dimming','a planet crossing its star''s face blocks a small fraction of starlight','repeating brightness dips reveal an orbiting body','discovering and measuring exoplanets'),
    (48,'Planetary Science','easy','impact cratering','high-velocity collisions','an incoming body excavates and ejects planetary surface material','a roughly circular depression and ejecta blanket form','estimating the relative ages of planetary surfaces'),
    (49,'Orbital Mechanics','hard','Kepler''s laws','elliptical orbits','orbital geometry and period relate systematically to distance from the central body','planetary speeds vary along predictable paths','calculating planetary motion'),
    (50,'Relativity','hard','gravitational time dilation','spacetime curvature','clocks deeper in a gravitational field run more slowly relative to distant clocks','elapsed time depends on gravitational potential','correcting satellite navigation clocks')
), angles(angle_no) as (select generate_series(1,10)), generated as (
  select
    'SCI-' || lpad(((s.topic_no - 1) * 10 + a.angle_no)::text, 4, '0') id,
    s.*,
    case a.angle_no
      when 1 then format('Which scientific concept is described by this statement: %s?', s.mechanism)
      when 2 then format('Name the principle or process in %s that explains how %s.', s.subcategory, s.result)
      when 3 then format('Which key term is most directly associated with %s?', s.concept)
      when 4 then format('In the context of %s, what produces this result: %s?', s.concept, s.result)
      when 5 then format('Which concept would a scientist apply when %s?', s.application)
      when 6 then format('Identify the concept connecting %s with the fact that %s.', s.key_term, s.result)
      when 7 then format('What scientific idea explains why %s?', s.mechanism)
      when 8 then format('A student is %s. Which concept is most relevant?', s.application)
      when 9 then format('Within %s, which term belongs at the center of the explanation?', s.concept)
      else format('Complete the scientific statement: %s leads to the conclusion that ____ is occurring.', s.mechanism)
    end question,
    case a.angle_no when 3 then s.key_term when 4 then s.mechanism when 9 then s.key_term else s.concept end answer,
    case when s.topic_no % 5 in (1,2) then 'easy' when s.topic_no % 5 in (3,4) then 'medium' else s.difficulty end level
  from source_facts s cross join angles a
)
insert into public.questions (
  id, accepted_answer, aliases, published, category, subcategory, difficulty,
  question_type, region, time_period, tags, question, options,
  correct_answer, explanation, content_status
)
select id, answer, '{}', true, 'Science', subcategory, level,
  'short_answer', 'Global', 'Modern', array[concept,key_term], question,
  '[]'::jsonb, to_jsonb(answer),
  format('%s centers on %s: %s. This means %s and is useful when %s.', concept, key_term, mechanism, result, application),
  'published'
from generated
on conflict (id) do update set
  accepted_answer=excluded.accepted_answer, aliases=excluded.aliases,
  published=excluded.published, category=excluded.category,
  subcategory=excluded.subcategory, difficulty=excluded.difficulty,
  question_type=excluded.question_type, region=excluded.region,
  time_period=excluded.time_period, tags=excluded.tags,
  question=excluded.question, options=excluded.options,
  correct_answer=excluded.correct_answer, explanation=excluded.explanation,
  content_status=excluded.content_status, updated_at=now();

do $$
begin
  if (select count(*) from public.questions where id between 'SCI-0001' and 'SCI-0500') <> 500 then
    raise exception 'Expected exactly 500 questions in science batch 1';
  end if;
  if (select count(distinct question) from public.questions where id between 'SCI-0001' and 'SCI-0500') <> 500 then
    raise exception 'Science batch 1 contains duplicate prompts';
  end if;
end;
$$;
