delete from MBEAN_REGISTRY;
update stub_property set PROPERTY_VALUE = 'true' where PROPERTY_NAME = 'sanitycheck.enable';
commit;
