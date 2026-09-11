# Hed t/k

Data, methods and code underlying this Center for Collaborative Investigative Journalism article examining arrests made by Immigration and Customs Enforcement (ICE) under the second Trump administration, co-published with the member stations of the [Gulf States Newsroom](https://www.canva.com/design/DAG--fxtMG4/FaZ1C_7kqq-3qnEGRXr0Cg/view?utm_content=DAG--fxtMG4&utm_campaign=designshare&utm_medium=link2&utm_source=uniquelinks&utlId=h7661611f93#1), a regional public media collaboration covering Alabama, Louisiana and Mississippi.

### Data methods and code

The analysis uses [data](https://deportationdata.org/data/processed/ice.html#latest-data-release) on arrests by ICE compiled by the [Deportation Data Project](https://deportationdata.org/index.html), run from UC Berkeley and UCLA. Parts of the analysis depend on information on the apprehension site landmark field (for an earlier release of data covering arrests through March 10, 2026) or event landmark field (for the latest data release, covering arrests through August 6, 2026). The event landmark field in the newer data release is more sparsely populated. So to avoid information loss we combined data from the two releases, using the prior release for arrests from January 20, 2025 to February 28, 2026 and the new release for arrests from March 1, 2026.)

The script `arrests.R` analyzes ICE arrests by state and ICE office area of responsibility, relating the numbers to data on the population by immigrant status (citizen and noncitizen) from the 2024 5-year American Community Survey. For arrests identified as occurring in Alabama, Louisiana and Mississippi, it also summarizes the number of arrests per entry in the apprehension site/event landmark fields.

Subsequent analysis depended upon manual annotation of information the apprehension site/event landmark fields to identify transfers from i) other federal agencies/federal correctional institutions ii) state prisons iii) county or parish jails iv) local police departments and to note arrest location by county. The results of this analysis are recorded in the spreadsheet `gulf_states_ice_arrests.xlsx` in the `processed_data` folder.

### **Questions/Feedback**

Email [Peter Aldhous](mailto:p.aldhous@ccij.io).
