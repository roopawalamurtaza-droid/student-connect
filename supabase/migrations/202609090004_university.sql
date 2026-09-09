-- Approved by the project owner using a sample university email address.
insert into private.allowed_email_domains(domain) values('ppsu.ac.in') on conflict do nothing;
