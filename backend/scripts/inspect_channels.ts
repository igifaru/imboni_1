
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('--- Channel Inspection ---');
    const channels = await prisma.communityChannel.findMany({
        include: {
            _count: {
                select: { messages: true }
            },
            administrativeUnit: true
        }
    });

    for (const c of channels) {
        if (c._count.messages > 0) {
            console.log(`[${c.type}] ${c.name} (Level: ${c.administrativeUnit?.level}) - ID: ${c.id} - Messages: ${c._count.messages}`);
        }
    }
    console.log('--------------------------');

    // Also check specifically for "General" channels which might be named simply by the Unit name or "General"
    const generalChannels = channels.filter(c => c.category === null || c.name.includes('General') || c.type === 'COMMUNITY');
    console.log('--- General/Community Channels (Even empty) ---');
    for (const c of generalChannels) {
        console.log(`[${c.type}] ${c.name} (Level: ${c.administrativeUnit?.level}) - ID: ${c.id} - Messages: ${c._count.messages}`);
    }
}

main()
    .catch(e => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
